import 'dart:io';
import 'package:flutter/material.dart';
import 'package:directory_picker/directory_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QUIT',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      home: MyHomePage(title: 'Quick Image Tagger'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //int _counter = 0;

  void _incrementCounter() {
    setState(() {
      //_counter++;
    });
  }

  Directory selectedDirectory = new Directory('/sdcard');
  Image shownImage = Image.network(
    'https://moorestown-mall.com/noimage.gif',
    fit: BoxFit.cover,
  );
  var readPaths = [];

  Future<void> _pickDirectory(BuildContext context) async {
    Directory directory = selectedDirectory;
    if (directory == null) {
      directory = await getExternalStorageDirectory();
    }

    Directory newDirectory = await DirectoryPicker.pick(
      context: context,
      rootDirectory: directory,
      /*shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))*/
    );

    setState(() {
      selectedDirectory = newDirectory;
      if (selectedDirectory != null) {
        Directory delDir =
            new Directory('${selectedDirectory.path}/quit_delete');
        Directory keepDir =
            new Directory('${selectedDirectory.path}/quit_keep');
        delDir.exists().then((doesIt) => {!doesIt ? delDir.create() : null});
        keepDir.exists().then((doesIt) => {!doesIt ? keepDir.create() : null});
      }
      var valid = ['jpg', 'png', 'jpeg', 'bmp'];
      var picked = false;
      print('diay');
      selectedDirectory.list().length.then((v) => {
            print('awesome: $v'),
            if (v > 0)
              {
                selectedDirectory.list().forEach((f) => valid.forEach((ext) => {
                      if (f.path.toLowerCase().endsWith(ext))
                        {print('file: ${f.path}'), readPaths.add(f.path)},
                      if (!picked)
                        {
                          shownImage = Image.asset(f.path),
                          picked = true,
                          print("boop")
                        },
                      print('elementos vivos: ${readPaths.length}'),
                    }))
              },
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.folder),
              onPressed: () => _pickDirectory(context)),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text(
              'Browsing: ${selectedDirectory.path}',
            ),
            Container(
                width: 360,
                height: 400,
                color: Colors.red,
                alignment: AlignmentDirectional(0.0, 0.0),
                child: ClipRect(
                    child: new PhotoView(
                  backgroundDecoration:
                      new BoxDecoration(color: Colors.grey[300]),
                  imageProvider: shownImage.image,
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: 4.0,
                ))),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                /*Text(
                  '$_counter',
                  style: Theme.of(context).textTheme.display1,
                ),*/
                IconButton(
                  icon: Icon(Icons.skip_previous),
                  tooltip: 'Previous',
                  color: Colors.black,
                  onPressed: () {
                    setState(() {});
                  },
                ),
                Ink(
                    decoration: ShapeDecoration(
                      color: Colors.grey,
                      shape: CircleBorder(),
                    ),
                    child: IconButton(
                        icon: Icon(Icons.delete),
                        tooltip: 'Delete',
                        color: Colors.red,
                        iconSize: 56,
                        onPressed: () {
                          setState(() {});
                        })),
                IconButton(
                  icon: Icon(Icons.undo),
                  tooltip: 'Undo',
                  color: Colors.yellow,
                  onPressed: () {
                    setState(() {});
                  },
                ),
                Ink(
                    decoration: ShapeDecoration(
                        color: Colors.grey, shape: CircleBorder()),
                    child: IconButton(
                        icon: Icon(Icons.check),
                        tooltip: 'Keep',
                        color: Colors.green,
                        iconSize: 56,
                        onPressed: () {
                          setState(() {});
                        })),
                IconButton(
                  icon: Icon(Icons.skip_next),
                  tooltip: 'Skip next',
                  color: Colors.black,
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ],
            )
          ],
        ),
      ),
      //floatingActionButton: FloatingActionButton(
      //  onPressed: _incrementCounter,
      //  tooltip: 'Increment',
      //  child: Icon(Icons.undo),
      //), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
