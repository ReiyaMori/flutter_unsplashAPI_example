import 'package:flutter/material.dart';
import 'package:unsplash_client/unsplash_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: 'Unsplash example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(visualDensity: VisualDensity.adaptivePlatformDensity),
      home: SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final client = UnsplashClient(
    settings: ClientSettings(
        credentials: AppCredentials(
      accessKey: '',                          //Edit
      secretKey: '',                          //Edit
    )),
  );
  TextEditingController? _controller;
  ScrollController? _scrollController;
  String? query;
  Future<List<Photo>>? photos;
  List<Photo>? toShowPhotos;
  int page = 0;

  @override
  void initState() {
    _controller = TextEditingController(text: 'stylish');
    _scrollController = ScrollController();
    query = 'stylish';
    page = 0;
    photos = _search(query);
    _scrollController!.addListener(() {
      final maxScrollExtent = _scrollController!.position.maxScrollExtent;
      final currentPosition = _scrollController!.position.pixels;
      if (maxScrollExtent > 0 && (maxScrollExtent - 20.0) <= currentPosition) {
        _addContents();
      }
    });
    super.initState();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
          appBar: AppBar(
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextFormField(
                controller: _controller,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    hintText: 'search',
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                    icon: Icon(Icons.search)),
                onChanged: (value) => query = value,
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    FocusScopeNode currentFocus = FocusScope.of(context);
                    if (!currentFocus.hasPrimaryFocus) {
                      currentFocus.unfocus();
                    }
                    setState(() {
                      photos = _search(query);
                    });
                  },
                  child: Text('SERCH'))
            ],
          ),
          body: FutureBuilder(
              future: photos,
              builder: (context, AsyncSnapshot<List<Photo>> snapshot) {
                toShowPhotos = snapshot.data;
                if (snapshot.hasData) {
                  return GridView.count(
                    controller: _scrollController,
                    crossAxisCount: 2,
                    children: toShowPhotos!.map((photo) {
                      if (photo.urls.thumb.toString().isEmpty)
                        return Container();
                      return Container(
                        padding: const EdgeInsets.all(5),
                        child: InkWell(
                            onTap: () =>
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => PhotoViewPage(
                                          photo: photo,
                                        ))),
                            child: Image.network(photo.urls.thumb.toString())),
                      );
                    }).toList(),
                  );
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  return Center(
                    child: Text('Find photos!'),
                  );
                }
              })),
    );
  }

  Future<String?> _getPhotoRamdom() async {
    List<Photo> photos = await client.photos.random(count: 1).goAndGet();
    Uri uri = photos.first.urls.thumb;
    return uri.toString();
  }

  Future<List<Photo>>? _search(String? query) async {
    page = 1;
    print('serch : $query');
    if (query!.isEmpty || query == '') return [];
    try {
      var result = await client.search.photos(query, page: page).goAndGet();
      print(result.totalPages);
      return result.results;
    } catch (e) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(e.toString()),
            );
          });
      print(e.toString());
      return [];
    }
  }

  void _addContents() async {
    page++;
    var result = await client.search.photos(query!, page: page).goAndGet();
    print('add : ${result.total}');
    setState(() {
      toShowPhotos!.addAll(result.results);
    });
  }
}

class PhotoViewPage extends StatelessWidget {
  Photo photo;
  PhotoViewPage({required this.photo}) : super();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo view'),
      ),
      body: Center(
        child: Container(child: Image.network(photo.urls.regular.toString())),
      ),
    );
  }
}
