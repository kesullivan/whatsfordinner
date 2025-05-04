import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<List<Recipe>> fetchRecipes() async {
  final file = File('recipes.json');
  final contents = await file.readAsString();

  // Use compute to parse in a background isolate (good practice for big files)
  return compute(parseRecipes, contents);
}

// Parses the file contents into a List<Recipe>
List<Recipe> parseRecipes(String responseBody) {
  final parsedJson = jsonDecode(responseBody) as Map<String, dynamic>;
  final recipesList = parsedJson['recipes'] as List;

  return recipesList.map<Recipe>((json) => Recipe.fromJson(json)).toList();
}

class Recipe {
  final String name;
  final String description;
  final String image;
  final List<Ingredient> ingredients;

  Recipe({
    required this.name,
    required this.description,
    required this.image,
    required this.ingredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    var ingredients =
        (json['ingredients'] as List)
            .map((item) => Ingredient.fromJson(item))
            .toList();

    return Recipe(
      name: json['name'],
      description: json['description'],
      image: json['image'],
      ingredients: ingredients,
    );
  }
}

class Ingredient {
  final String name;
  final String quantity;
  final String unit;

  Ingredient({required this.name, required this.quantity, required this.unit});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'],
      quantity: json['quantity'],
      unit: json['unit'],
    );
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appTitle = 'Whats For Dinner';

    return const MaterialApp(
      title: appTitle,
      home: MyHomePage(title: appTitle),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    DinnerTonight(),
    RecipesListBuilder(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color.fromARGB(255, 206, 206, 206),
      ),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem> [
          BottomNavigationBarItem(icon: Icon(Icons.food_bank_outlined), label: "Dinner"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "All Dinners")
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[900],
        onTap: _onItemTapped,
      ),
    );
  }
}

class DinnerTonight extends StatelessWidget{
  const DinnerTonight({super.key});
  // int _selectedIndex = 0;
  static const TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const Text buttonText = Text("Get Dinner", style: optionStyle);

  void _onPressed() {
    return;
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _dialogBuilder(context),
      style: TextButton.styleFrom (
        maximumSize: Size(350, 50),
        overlayColor: Colors.transparent,
      ), 
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 30.0),
          alignment: Alignment.center,
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            gradient: LinearGradient(
              colors: [
                Colors.amber[100]!,
                Colors.amber[900]!,
              ]
            ),
            boxShadow: [
              BoxShadow(
                offset: Offset(0, 0),
                color: Colors.amber[100]!,
                blurRadius: 16.0,
              ),
              BoxShadow(
                offset: Offset(0, 0),
                color: Colors.amber[200]!,
                blurRadius: 16.0,
              ),
              BoxShadow(
                offset: Offset(0, 0),
                color: Colors.amber[300]!,
                blurRadius: 16.0,
              ),
            ]
          ),
          child: Stack(
            // Gets black border on text
            children: <Widget>[
              Text(
                'Decide Dinner',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20.0,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 2
                    ..color = Colors.black,
                ),
              ),
              Text(
                'Decide Dinner',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20.0,
                  color: Colors.white,
                ),
              )
            ],
          )
          //Text("Decide Dinner", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18.0))
        ),
      )
    );
  }
}

Future<void> _dialogBuilder(BuildContext context) async {
  final recipes = await fetchRecipes();
  final random = Random();
  final randomRecipe = recipes[random.nextInt(recipes.length)];

  if (!context.mounted) return; 

  showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Tonight for Dinner!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [ 
            Text(
              randomRecipe.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(randomRecipe.description),
            _checkIfImageExists(randomRecipe.image)
                ? Image.file(File(randomRecipe.image), width: 300, height: 300, fit: BoxFit.cover)
                : const Icon(Icons.fastfood),
          ],
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('not tonight thank you though'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('YES'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      );
    },
  );
}


class RecipesListBuilder extends StatelessWidget {
  const RecipesListBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Recipe>>(
        future: fetchRecipes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('An error has occurred!'));
          } else if (snapshot.hasData) {
            return RecipesList(recipes: snapshot.data!);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
  }

}

bool _checkIfImageExists(String path) {
  return File(path).existsSync();
}

class RecipesList extends StatelessWidget {
  const RecipesList({super.key, required this.recipes});

  final List<Recipe> recipes;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return Card(
          child: ListTile(
            leading: _checkIfImageExists(recipe.image)
                ? Image.file(File(recipe.image), width: 50, height: 50, fit: BoxFit.cover)
                : const Icon(Icons.fastfood),
            title: Text(recipe.name),
            subtitle: Text(recipe.description),
            onTap: () {
              // navigate to a detail screen
            },
          ),
        );
      },
    );
  }
}
