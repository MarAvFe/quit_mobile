import 'dart:io';
import 'package:flutter/material.dart';
import 'package:directory_picker/directory_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: 'Quick Tag',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      home: MyHomePage(title: 'Quick Tag'),
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
  @override
  Widget build(BuildContext context) {
    var radius10 = new BorderRadius.all(const Radius.circular(10.0));
    var scale = PhotoViewComputedScale.contained;
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.65,
        alignment: AlignmentDirectional(0.0, 0.0),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: new Border.all(color: Colors.grey[500], width: 3),
          borderRadius: radius10,
        ),
        child: ClipRRect(
            borderRadius: new BorderRadius.all(const Radius.circular(7)),
            child: new PhotoView(
              backgroundDecoration: new BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: radius10,
              ),
              imageProvider: widget.path != ''
                  ? Image.asset(widget.path).image
                  : AssetImage('images/no-image-found.png'),
              initialScale: scale,
              minScale: scale,
              maxScale: scale, //4.0,
            )));
  }
}

class _MyHomePageState extends State<MyHomePage> {
  Directory selectedDirectory = new Directory('/storage/emulated/0');
  var readPaths = [];
  var history = [];
  var workingIdx = 0;
  static const KEEP = true;
  static const DELETE = false;
  static const BACK = true;
  static const FORWARD = false;

  Future<bool> classifyImage(bool keep) async {
    try {
      String oldFile = readPaths[workingIdx];
      String newFilePath =
          '${selectedDirectory.path}/${keep ? 'quit_keep' : 'quit_delete'}/${readPaths[workingIdx].split("/").last}';
      await moveImage(oldFile, newFilePath);
      history.add('$newFilePath');
      readPaths.removeAt(workingIdx);
      if (workingIdx == readPaths.length) moveIdx(BACK);
    } catch (e) {
      print('Exception: $e');
      return false;
    }
    return true;
  }

  Future<void> moveImage(String file, String dst) async {
    print('move: $file -> $dst');
    var contents = await new File(file).readAsBytes();
    File newFile = File(dst);
    newFile.writeAsBytes(contents);
    await new File(file).delete();
  }

  Future<void> undo() async {
    String historyFile = history.last;
    String historyFileName = historyFile.split('/').last;
    String restoredFile = '${selectedDirectory.path}/$historyFileName';
    print('undo: $historyFile -> ${selectedDirectory.path}');
    await moveImage(historyFile, restoredFile);
    history.removeLast();
    readPaths.insert(workingIdx, restoredFile);
    setState(() {});
  }

  void moveIdx(bool direction) {
    workingIdx += direction == FORWARD ? 1 : -1;
    workingIdx = readPaths.length != 0 ? workingIdx % readPaths.length : 0;
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

    if (newDirectory != null) {
      setState(() {
        selectedDirectory = newDirectory;
        if (selectedDirectory != null) {
          Directory delDir =
              new Directory('${selectedDirectory.path}/quit_delete');
          Directory keepDir =
              new Directory('${selectedDirectory.path}/quit_keep');
          delDir.exists().then((doesIt) => {!doesIt ? delDir.create() : null});
          keepDir
              .exists()
              .then((doesIt) => {!doesIt ? keepDir.create() : null});
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
              'Browsing: (${readPaths.length == 0 ? '0' : (workingIdx + 1)}/${readPaths.length}) ${selectedDirectory.path}',
            ),
            ImageViewer(
                path: readPaths.length == 0 ? '' : readPaths[workingIdx]),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Ink(
                    decoration: ShapeDecoration(
                      color: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.skip_previous),
                      tooltip: 'Previous',
                      color: Colors.black,
                      onPressed: () {
                        setState(() {
                          moveIdx(BACK);
                        });
                      },
                    )),
                // ? as
                // ! important
                Ink(
                    decoration: ShapeDecoration(
                      color: Colors.brown[50],
                      shape: CircleBorder(),
                    ),
                    child: IconButton(
                        icon: Icon(Icons.delete),
                        tooltip: 'Delete',
                        color: Colors.red,
                        iconSize: 56,
                        onPressed: () {
                          setState(() {
                            classifyImage(DELETE).then((success) => {
                                  setState(() {}),
                                });
                          });
                        })),
                Ink(
                    decoration: ShapeDecoration(
                      color: Colors.grey.shade100,
                      //gradient: Gradient(colors: [Colors.red, Colors.blue]),
                      shape: CircleBorder(),
                    ),
                    child: IconButton(
                        icon: Icon(Icons.undo),
                        tooltip: 'Undo',
                        color: Colors.yellow[600],
                        onPressed: history.length <= 0
                            ? null
                            : () {
                                setState(() {
                                  undo();
                                });
                              })),
                Ink(
                    decoration: ShapeDecoration(
                        color: Colors.brown[50], shape: CircleBorder()),
                    child: IconButton(
                        icon: Icon(Icons.save),
                        tooltip: 'Keep',
                        color: Colors.green,
                        iconSize: 56,
                        onPressed: () {
                          setState(() {
                            classifyImage(KEEP).then((success) => {
                                  setState(() {}),
                                });
                          });
                        })),
                Ink(
                    decoration: ShapeDecoration(
                      color: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.skip_next),
                      tooltip: 'Skip next',
                      color: Colors.black,
                      onPressed: () {
                        setState(() {
                          moveIdx(FORWARD);
                        });
                      },
                    )),
              ],
            )
          ],
        ),
      ),
    );
  }
}
