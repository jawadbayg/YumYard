import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: RecipeSearchPage(),
    );
  }
}

class RecipeSearchPage extends StatefulWidget {
  const RecipeSearchPage({super.key});

  @override
  State<RecipeSearchPage> createState() => _RecipeSearchPageState();
}

class _RecipeSearchPageState extends State<RecipeSearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _recipes = []; // Changed to dynamic
  // Add other necessary variables
  Future<void> _searchRecipes(String searchTerm) async {
    final String host = "all-in-one-recipe-api.p.rapidapi.com";
    final String apiKey = "3219a68b92msh29b6e8a5f3ac678p1f555fjsnd1399975bbb0";
    final String searchPath = "/search/$searchTerm";

    final Uri uri = Uri.https(host, searchPath);

    try {
      final response = await http.get(uri, headers: {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': host,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> recipesData = responseData['recipes']['data'];

        final List<Map<String, dynamic>> recipes =
            recipesData.map<Map<String, dynamic>>((recipe) {
          return {
            'id': recipe['id'].toString(),
            'name': recipe['name'],
          };
        }).toList();

        setState(() {
          _recipes = recipes;
        });
      } else {
        throw Exception('Failed to search recipes');
      }
    } catch (error) {
      print('Error searching recipes: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.pink.shade200,
        title: Text(
          'YumYard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade200, Colors.pink.shade400],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "What do you want\nto cook today?",
                    style: TextStyle(
                        fontSize: 35.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Enter recipe name',
                  hintStyle: TextStyle(color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.search,
                      color: Colors.pink,
                    ),
                    onPressed: () {
                      _searchRecipes(_searchController.text);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _recipes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      elevation: 3,
                      child: ListTile(
                        title: Text(
                          _recipes[index]['name'].toString(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle:
                            Text('ID: ${_recipes[index]['id'].toString()}'),
                        trailing: Icon(Icons.arrow_forward),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeDetailsPage(
                                recipeId: _recipes[index]['id'].toString(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeDetailsPage extends StatefulWidget {
  final String recipeId;

  RecipeDetailsPage({required this.recipeId});

  @override
  _RecipeDetailsPageState createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  Map<String, dynamic>? _recipeDetails;

  Future<void> _fetchRecipeDetails() async {
    final String apiKey = "3219a68b92msh29b6e8a5f3ac678p1f555fjsnd1399975bbb0";
    final String host = "all-in-one-recipe-api.p.rapidapi.com";
    final String detailsPath = "/details/${widget.recipeId}";

    final Uri uri = Uri.https(host, detailsPath);
    final response = await http.get(uri, headers: {
      'X-RapidAPI-Key': apiKey,
      'X-RapidAPI-Host': host,
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('recipe') && data['recipe'].containsKey('data')) {
        setState(() {
          _recipeDetails = data['recipe']['data'];
        });
      } else {
        throw Exception('Invalid response format: Recipe data not found');
      }
    } else {
      throw Exception('Failed to load recipe details');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Details'),
      ),
      body: _recipeDetails == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _recipeDetails!['Name'],
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  _buildTile('Description', _recipeDetails!['Description']),
                  _buildTile(
                      'Ingredients', _recipeDetails!['Ingredients'].join('\n')),
                  _buildTile(
                      'Directions', _recipeDetails!['Directions'].join('\n')),
                  _buildTile('Nutritional Information',
                      _recipeDetails!['Nutritions'].join('\n')),
                  _buildTile('Rating', _recipeDetails!['Rating']),
                  _buildTile('Category', _recipeDetails!['Category']),
                  _buildTile('Cuisine', _recipeDetails!['Cuisine']),
                ],
              ),
            ),
    );
  }

  Widget _buildTile(String title, String content) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pinkAccent, Colors.pink],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            content,
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class CarouselPage extends StatelessWidget {
  final List<String> imagePaths = [
    'assets/reca.jpg',
    'assets/recc.jpg',
    'assets/reca.jpg',
    // Add more image paths here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Picture Carousel'),
      ),
      body: Center(
        child: CarouselSlider(
          options: CarouselOptions(
            autoPlay: true,
            aspectRatio: 16 / 9,
            enlargeCenterPage: true,
          ),
          items: imagePaths.map((imagePath) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                  ),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
