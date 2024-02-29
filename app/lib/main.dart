import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';


// -------------- Created By Collin Shook -----------------------------------


void main()
{
  runApp(MaterialApp(
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder>{
        "/HomePage": (BuildContext context) => const HomePage(),
        "/Content": (BuildContext context) => const MyApp()

      }));
}


// class that stores all information about each business that is returned in a query
class Business
{
  String name;
  String businessType = "";
  String? subType;
  String? phone;
  String? website;
  String? openHours;
  String? takeaway;
  String? delivery;
  String? addrCity;
  String? addrNum;
  String? addrState;
  String? addrStreet;

  Business(
      this.name,
      this.businessType,
      this.subType,
      this.phone,
      this.website,
      this.openHours,
      this.takeaway,
      this.delivery,
      this.addrCity,
      this.addrNum,
      this.addrState,
      this.addrStreet
      );

}


class HomePage extends StatefulWidget
{
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with SingleTickerProviderStateMixin
{
  int selectedIndex = 0;

  // image widget
  static Widget myImage(String imgPath)
  {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)
      ),
      child: ClipRect(
          child: Image.asset(imgPath)
      ),
    );
  }

  // create a list for the two tabs on the home page
  List<Widget> createTabs(BuildContext context)
  {
    List<Widget> tabs = [
     ListView(
         children: [
           const Divider(height: 50),
           const Text(
             "Find Restaruants, Shops and Hotels near you!",
             style: TextStyle(
               color: Colors.white,
               fontSize: 30,
               fontWeight: FontWeight.bold,

             ),
             textAlign: TextAlign.center,
           ),

           const Divider(height: 50),

           ElevatedButton(
               onPressed: () => Navigator.of(context).pushNamed("/Content"),
               child: const Text("Go To Locator")
           ),

           const Divider(height: 50),

           Column(
             children: [
               myImage("images/restaurant.jpg"),
               const Divider(height: 20),
               myImage("images/store.JPG"),
               const Divider(height: 20),
               myImage("images/hotel.jpg")
             ],
           )
         ]
     ),

    ListView(
       children: const [
         Divider(height: 20),
         Text("Created by Collin Shook for Final Mobile Apps Project",
           style: TextStyle(
               color: Colors.white
           )
         ),
         Divider(height: 20),
         Text("Data provided by OpenStreetMap",
             style: TextStyle(
                 color: Colors.white
             )
         )
       ]

     )

   ];

    return tabs;
 }

 // this function is the called when the bottom bar is tapped
  void onItemTapped(int index)
  {
    setState(()
    {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context)
  {
    List<Widget> tabs = createTabs(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Finder"),
        backgroundColor: const Color.fromRGBO(25, 25, 25, 1),
      ),
      backgroundColor: const Color.fromRGBO(50, 50, 50, 1),
      body: tabs.elementAt(selectedIndex),
      bottomNavigationBar: BottomNavigationBar(

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.house),
              label: "Home",

            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info),
              label: "About",
              backgroundColor: Colors.black
            )
          ],
          currentIndex: selectedIndex,
          selectedItemColor: Colors.black,
          onTap: onItemTapped
      ),
    );
  }

}


class MyApp extends StatefulWidget
{
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with SingleTickerProviderStateMixin
{

  // a list of all the businesses to show in the app list
  static List<Business> businesses = [];


  // text controllers for inputing the latitude and longitude
  TextEditingController tcLat = TextEditingController();
  TextEditingController tcLon = TextEditingController();

  // default coordinates (Kalispell, MT)
  double lat = 48.19164531740691;
  double lon = -114.31439982644251;

  // default slider values (10 mi.)
  double searchDist = 10;
  double _distSliderValue = 10;

  // Booleans for the checkboxes
  static bool queryRestaurants = true;
  static bool queryShops = true;
  static bool queryHotels = true;


  static var overpassData;


  // this function queries the overpass api to get business data around the given
  // coordinates and distance (meters)
  static Future<Map<String, dynamic>?> getOverpassData(num lat, num lon, num radius) async
  {
    // overpass api url
    var url = Uri.parse("https://overpass-api.de/api/interpreter");

    // tags for each overpass query type
    String restaurantTags = '"amenity"~"bar|biergarten|cafe|fast_food|food_court|ice_cream|pub|restaurant"';
    String shopTags = '"shop"';
    String hotelTags = '"tourism"="hotel"';

    //  -------------- queries for each business type ----------------------
    String restaurantQuery = """
      [out:json];
      (
        node(around:$radius,$lat,$lon)[$restaurantTags];
      );

      
      out body;
      >;
      out skel qt;
    """;

    String shopQuery = """
      [out:json];
      (
        node(around:$radius,$lat,$lon)[$shopTags];
      );

      
      out body;
      >;
      out skel qt;
    """;

    String hotelQuery = """
      [out:json];
      (
        node(around:$radius,$lat,$lon)[$hotelTags];
      );

      
      out body;
      >;
      out skel qt;
    """;

    //  -------------- end queries for each business type ----------------------


    // clear the current businesses list
    businesses.clear();

    // if the restaurant checkbox is selected
    if(queryRestaurants)
    {
      // POST to the api
      http.Response restaurantResponse = await http.post(
          url, body: restaurantQuery);

      // decode the JSON response
      var restaurantData = await jsonDecode(restaurantResponse.body);

      // add the data to the businesses list as a restaurant
      inputDataIntoBusinessList(restaurantData, "restaurant");

      // this only makes sure that overpass data isn't null, otherwise my code didn't work
      overpassData = restaurantData;
    }

    if(queryShops)
    {
      // POST to the api
      http.Response shopResponse = await http.post(url, body: shopQuery);

      // decode the JSON response
      var shopData = await jsonDecode(shopResponse.body);

      // add the data to the businesses list as a shop
      inputDataIntoBusinessList(shopData, "shop");

      // this only makes sure that overpass data isn't null, otherwise my code didn't work
      overpassData = shopData;
    }

    if(queryHotels)
    {
      // POST to the api
      http.Response hotelResponse = await http.post(url, body: hotelQuery);

      // decode the JSON response
      var hotelData = await jsonDecode(hotelResponse.body);

      // add the data to the businesses list as a hotel
      inputDataIntoBusinessList(hotelData, "hotel");

      // this only makes sure that overpass data isnt null, otherwise my code didn't work
      overpassData = hotelData;
    }

    // sort the businesses alphabetically by name
    businesses.sort((a, b) => a.name.compareTo(b.name));

    return overpassData;
  }

  // adds the JSON data to the businesses list
  static void inputDataIntoBusinessList(var data, String businessType)
  {
    // iterate through JSON
    for(int i = 0; i < data['elements'].length; i++)
    {
      // business subtype logic
      String? subType;

      if(businessType == "restaurant")
      {
        subType = data['elements'][i]['tags']['cuisine'];
      }
      else if(businessType == "shop")
      {
        subType = data['elements'][i]['tags']['shop'];
      }

      // create a new Business object
      Business b = Business(
          data['elements'][i]['tags']['name'],
          businessType,
          subType,
          data['elements'][i]['tags']['phone'],
          data['elements'][i]['tags']['contact:website'],
          data['elements'][i]['tags']['opening_hours'],
          data['elements'][i]['tags']['takeaway'],
          data['elements'][i]['tags']['takeaway'],
          data['elements'][i]['tags']['addr:city'],
          data['elements'][i]['tags']['addr:housenumber'],
          data['elements'][i]['tags']['addr:state'],
          data['elements'][i]['tags']['addr:street']
      );

      // add the business to our list
      businesses.add(b);

    }
  }


  // gets user's location if location services are enabled
  void getLocation() async
  {
    // get the coordintates of phone with high accuracy using Geoloctor
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // update the latitude and longitude textboxes with the new position data
    setState(()
    {
      lat = position.latitude;
      lon = position.longitude;

      tcLat.text = "$lat";
      tcLon.text = "$lon";
    });
  }

  // convert miles to meters
  double milesToMeters(double searchDist) => searchDist * 1609.34;

  // this function re-calls the data retrieval function when the locate button is pressed
  Future<void> locateBusinesses() async
  {
    double distInMeters = milesToMeters(searchDist);
    lat = double.parse(tcLat.text);
    lon = double.parse(tcLon.text);

    try
    {
      var newData = await getOverpassData(lat, lon, distInMeters);

      setState(()
      {
        overpassData = newData;
      });


    }
    catch (error)
    {
      print("Error fetching data: $error");
    }
  }

  // business list future builder
  Widget overpassWidget = FutureBuilder(
      future: getOverpassData(48.19164531740691, -114.31439982644251, 16090),

      builder: (BuildContext context, AsyncSnapshot snapshot)
      {
        if (snapshot.hasData)
        {
          return SizedBox(
              height: 600, // Provide a fixed height here
              child: ListView.builder(
              itemCount: businesses.length,
              itemBuilder: (BuildContext context, int index)
              {
                List<Widget> cardChildren = [];

                Color cardColor = Colors.redAccent;

                Icon cardIcon = const Icon(
                    Icons.restaurant_rounded,
                    color: Colors.white
                );

                switch(businesses[index].businessType)
                {
                  case "restaurant":
                    cardColor = Colors.redAccent;
                    cardIcon = const Icon(
                      Icons.restaurant_rounded,
                      color: Colors.white,
                      size: 30
                    );

                  case "shop":
                    cardColor = Colors.blueAccent;
                    cardIcon = const Icon(
                      Icons.shopping_basket_rounded,
                      color: Colors.white,
                      size: 30
                    );
                  case "hotel":
                    cardColor = Colors.green;

                    cardIcon = const Icon(
                      Icons.hotel,
                      color: Colors.white,
                      size: 30
                    );
                }

                cardChildren.add(const Text(""));

                if(businesses[index].name != null)
                {
                  cardChildren.add(

                    SizedBox(
                      width: 400,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          cardIcon,
                          Text(
                            businesses[index].name!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800
                            ),
                            softWrap: true,
                          )
                        ]
                      )
                    )
                  );
                }

                if(businesses[index].subType != null)
                {
                  cardChildren.add(
                      Text(
                        businesses[index].subType!,
                        style: const TextStyle(color: Colors.white),
                      )
                  );
                }

                if(businesses[index].phone != null)
                {
                  cardChildren.add(
                      ElevatedButton(

                          onPressed: () async
                          {
                            String tel = businesses[index].phone!.replaceAll("[()\\s-]+", "");
                            final Uri url = Uri.parse("tel:$tel");
                            if (!await launchUrl(url))
                            {
                              throw Exception('Could not launch $url');
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                            [

                              const Icon(
                                Icons.phone,
                                color: Colors.white,

                              ),
                              Text(
                                "Call ${businesses[index].phone}",
                                style: const TextStyle(color: Colors.white),
                              )
                            ],
                          )
                      )
                  );
                }

                if(businesses[index].website != null)
                {
                  cardChildren.add(
                      ElevatedButton(

                          onPressed: () async
                          {
                            final Uri url = Uri.parse(businesses[index].website!);
                            if (!await launchUrl(url))
                            {
                              throw Exception('Could not launch $url');
                            }
                          },
                          child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                              [
                                Icon(
                                  Icons.open_in_browser_rounded,
                                  color: Colors.white,

                                ),
                                Text(
                                  "Visit Website",
                                  style: TextStyle(color: Colors.white),
                                )
                              ]
                          )
                      )
                  );
                }

                if(businesses[index].openHours != null)
                {
                  cardChildren.add(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                        [
                          const Icon(
                            Icons.watch_later_rounded,
                            color: Colors.white,

                          ),
                          Text(
                            businesses[index].openHours!,
                            style: const TextStyle(color: Colors.white),
                          )
                        ],
                      )
                  );
                }

                if(businesses[index].takeaway != null)
                {
                  cardChildren.add(
                      Text(
                        "Takeout: ${businesses[index].takeaway}",
                        style: const TextStyle(color: Colors.white),
                      )
                  );
                }

                if(businesses[index].delivery != null)
                {
                  cardChildren.add(
                      Text(
                        "Delivery: ${businesses[index].delivery}",
                        style: const TextStyle(color: Colors.white),
                      )
                  );
                }

                if(businesses[index].addrStreet != null &&
                    businesses[index].addrNum != null &&
                    businesses[index].addrState != null &&
                    businesses[index].addrCity != null)
                {
                  cardChildren.add(
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                          [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,

                            ),
                            Text(
                              "${businesses[index].addrNum} ${businesses[index].addrStreet} ${businesses[index].addrCity}, ${businesses[index].addrState}",
                              style: const TextStyle(color: Colors.white),
                            )
                          ]
                      )
                  );
                }

                return Card(
                    color: cardColor,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: cardChildren
                    )
                );
              }
              )
          );
        }

        return const Text("Getting Data" , style: TextStyle(color: Colors.white));

      }
  );



  // Latitude and longitude input widgets
  Row InputRow(double width, double height, String text, TextEditingController tc)
  {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            text,
            style: const TextStyle(
                color: Colors.white
            ),
          ),
          SizedBox(
              width: width,
              height: height,
              child: TextField(
                controller: tc,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    color: Colors.white
                ),
              )
          )
        ]
    );
  }

  // search radius slider widget
  Widget distanceSlider() {
    return Slider(
      activeColor: Colors.blueAccent,
      inactiveColor: Colors.blueAccent,
      max: 50,
      min: 1,
      value: _distSliderValue,
      onChanged: (double newvalue) {
        setState(() {
          searchDist = newvalue.roundToDouble();
          _distSliderValue = newvalue.roundToDouble();
        });
      },
    );
  }

  // checkbox widget
  Widget myCheckbox(String name, bool? val, Function(bool?) onChanged)
  {
    return CheckboxListTile(
      title: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold
        ),
      ),
      checkColor: Colors.white,
      activeColor: Colors.blueAccent,
      value: val,
      onChanged: onChanged,

    );
  }



  @override
  Widget build(BuildContext context)
  {
    tcLat.text = "$lat";
    tcLon.text = "$lon";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Locator"),
        backgroundColor: const Color.fromRGBO(25, 25, 25, 1),
      ),
      backgroundColor: const Color.fromRGBO(50, 50, 50, 1),
      body: ListView(
        children: [
          Column(
              children: [
                InputRow(300, 50, "Latitude", tcLat),
                InputRow(300, 50, "Longitude", tcLon),

                ElevatedButton(
                  onPressed: ()
                  {
                    getLocation();
                  },

                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                    [

                      Icon(
                        Icons.gps_fixed_rounded,
                        color: Colors.white,

                      ),
                      Text(
                        "Current Location",
                        style: TextStyle(color: Colors.white),
                      )
                    ],
                  ),
                ),

                Text("Within $searchDist mi", style: const TextStyle(color: Colors.white)),
                distanceSlider(),

                myCheckbox("Restaurants", queryRestaurants, (newValue) {
                  setState(() {
                    queryRestaurants = newValue ?? false;
                  });
                }),

                myCheckbox("Shops", queryShops, (newValue) {
                  setState(() {
                    queryShops = newValue ?? false;
                  });
                }),

                myCheckbox("Hotels", queryHotels, (newValue) {
                  setState(() {
                    queryHotels = newValue ?? false;
                  });
                }),

                ElevatedButton(
                    onPressed: () => locateBusinesses(),

                    child: const Text("Locate Businesses")),
                Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(20),
                    child: const Text(
                        "Businesses Nearby",
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18
                        )
                    )
                ),

                overpassWidget
              ]
          )
        ]
      ),

    );
  }

}
