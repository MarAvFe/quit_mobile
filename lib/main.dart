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
        primarySwatch: Colors.lightGreen,
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

class ImageViewer extends StatefulWidget {
  ImageViewer({Key key, this.path}) : super(key: key);

  final String path;

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  Image shownImage = Image.network(
    'https://moorestown-mall.com/noimage.gif',
    fit: BoxFit.cover,
  );

  @override
  Widget build(BuildContext context) {
    var scale = PhotoViewComputedScale.contained;
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.65,
        alignment: AlignmentDirectional(0.0, 0.0),
        child: ClipRect(
            child: new PhotoView(
          backgroundDecoration: new BoxDecoration(color: Colors.grey[300]),
          imageProvider: Image.asset(widget.path).image,
          initialScale: scale,
          minScale: scale * 0.8,
          maxScale: 4.0,
        )));
  }
}

class _MyHomePageState extends State<MyHomePage> {
  Directory selectedDirectory = new Directory('/sdcard');
  var readPaths = [];
  var workingIdx = 0;
  static const KEEP = true;
  static const DELETE = false;

  Future<bool> moveImage(bool keep) async {
    //final path = await _localPath;
    // return File('$path/counter.txt');
    try {
      String oldFile = readPaths[workingIdx];
      var contents = await new File(oldFile).readAsBytes();
      String newFilePath =
          '${selectedDirectory.path}/${keep ? 'quit_keep' : 'quit_delete'}/${readPaths[workingIdx].split("/").last}';
      File newFile = File(newFilePath);
      newFile.writeAsBytes(contents);
      await new File(oldFile).delete();
    } catch (e) {
      print('Exception: $e');
      return false;
    }
    return true;
  }

  Future<void> _pickDirectory(BuildContext context) async {
    Directory directory = selectedDirectory;
    if (directory == null) {
      directory = await getExternalStorageDirectory();
    }

    Directory newDirectory = await DirectoryPicker.pick(
      context: context,
      rootDirectory: directory,
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
      readPaths = [];
      selectedDirectory.list().length.then((v) => {
            if (v > 0)
              {
                selectedDirectory
                    .list()
                    .forEach((f) => valid.forEach((ext) => {
                          if (f.path.toLowerCase().endsWith(ext))
                            {readPaths.add(f.path)},
                        }))
                    .then((v) => {
                          print('algo pasa: $v, ${readPaths.length}'),
                          workingIdx = 0,
                          setState(() {}),
                        }),
              },
          });
    });
    print(workingIdx++);
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
            ImageViewer(
                path: readPaths.length == 0 ? '' : readPaths[workingIdx]),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.skip_previous),
                  tooltip: 'Previous',
                  color: Colors.black,
                  onPressed: () {
                    setState(() {
                      workingIdx = workingIdx > 0
                          ? workingIdx - 1
                          : readPaths.length - 1;
                    });
                  },
                ),
                Ink(
                    decoration: ShapeDecoration(
                      color: Colors.grey[200],
                      shape: CircleBorder(),
                    ),
                    child: IconButton(
                        icon: Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        color: Colors.red,
                        iconSize: 56,
                        onPressed: () {
                          setState(() {
                            moveImage(DELETE).then((success) => {
                                  if (success)
                                    {readPaths.remove(readPaths[workingIdx])},
                                  setState(() {}),
                                });
                          });
                        })),
                IconButton(
                  icon: Icon(Icons.undo),
                  tooltip: 'Undo',
                  color: Colors.yellow[600],
                  onPressed: null,
                ),
                Ink(
                    decoration: ShapeDecoration(
                        color: Colors.grey[200], shape: CircleBorder()),
                    child: IconButton(
                        icon: Icon(Icons.save),
                        tooltip: 'Keep',
                        color: Colors.green,
                        iconSize: 56,
                        onPressed: () {
                          setState(() {
                            moveImage(KEEP).then((success) => {
                                  if (success)
                                    {readPaths.remove(readPaths[workingIdx])},
                                  setState(() {}),
                                });
                          });
                        })),
                IconButton(
                  icon: Icon(Icons.skip_next),
                  tooltip: 'Skip next',
                  color: Colors.black,
                  onPressed: () {
                    setState(() {
                      workingIdx = workingIdx < readPaths.length - 1
                          ? workingIdx + 1
                          : 0;
                    });
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
