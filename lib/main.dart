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
  BuildContext _scaffoldContext;
  var _workingIdx = 0;

  Directory selectedDirectory = new Directory('/storage/emulated/0');
  var readPaths = [];
  var history = [];

  static const KEEP = true;
  static const DELETE = false;
  static const BACK = true;
  static const FORWARD = false;
  static const MSGERRO = 1;
  static const MSGWARN = 2;
  static const MSGSUCC = 3;
  static const MSGINFO = 4;

  Future<bool> classifyImage(bool keep) async {
    try {
      String oldFile = readPaths[_workingIdx];
      String newFilePath =
          '${selectedDirectory.path}/${keep ? 'quit_keep' : 'quit_delete'}/${readPaths[_workingIdx].split("/").last}';
      await moveImage(oldFile, newFilePath);
      history.add('$newFilePath');
      readPaths.removeAt(_workingIdx);
      if (_workingIdx == readPaths.length) moveIdx(BACK);
    } catch (e) {
      showSnack("weird: $e", type: MSGERRO);
      return false;
    }
    return true;
  }

  Future<void> moveImage(String file, String dst) async {
    var contents = await new File(file).readAsBytes();
    File newFile = File(dst);
    newFile.writeAsBytes(contents);
    await new File(file).delete();
  }

  Future<void> undo() async {
    String historyFile = history.last;
    String historyFileName = historyFile.split('/').last;
    String restoredFile = '${selectedDirectory.path}/$historyFileName';
    await moveImage(historyFile, restoredFile);
    history.removeLast();
    readPaths.insert(_workingIdx, restoredFile);
    setState(() {});
  }

  void moveIdx(bool direction) {
    _workingIdx += direction == FORWARD ? 1 : -1;
    if (readPaths.length != 0) {
      _workingIdx = _workingIdx % readPaths.length;
    } else {
      _workingIdx = 0;
      showSnack("Last image tagged!", type: MSGSUCC);
    }
  }

  Future<String> _pickDirectory(BuildContext context) async {
    String result = "";
    Directory directory = selectedDirectory;
    if (directory == null) {
      directory = await getExternalStorageDirectory();
    }

    try {
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
            delDir
                .exists()
                .then((doesIt) => {!doesIt ? delDir.create() : null});
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
                              _workingIdx = 0,
                              setState(() {}),
                            }),
                  },
              });
        });
      }
    } on UnsupportedError {
      result = "throw alert of iOS not supported";
    } catch (e) {
      result = "unhandled exception: $e";
    }
    return result;
  }

  void showSnack(String text, {int type = 0}) {
    Color color;
    switch (type) {
      case 1:
        color = Colors.red;
        break;
      case 2:
        color = Colors.orange;
        break;
      case 3:
        color = Colors.green;
        break;
      case 4:
        color = Colors.lightBlue;
        break;
      default:
        color = Colors.grey.shade900;
    }
    Scaffold.of(_scaffoldContext).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    Widget body = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text(
            'Browsing: (${readPaths.length == 0 ? '0' : (_workingIdx + 1)}/${readPaths.length}) ${selectedDirectory.path}',
          ),
          ImageViewer(
              path: readPaths.length == 0 ? '' : readPaths[_workingIdx]),
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
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.folder),
              onPressed: () => _pickDirectory(context).then((onValue) =>
                  {if (onValue != "") showSnack(onValue, type: MSGERRO)})),
        ],
      ),
      body: new Builder(builder: (BuildContext context) {
        _scaffoldContext = context;
        return body;
      }),
    );
  }
}
