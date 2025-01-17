library server.main;

import 'dart:convert';
import 'dart:mirrors';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;


class User {
  bool admin = false;
  var username;

  static accessHiddenPage() {
    return 'Inside hidden page!';
  }

  accessAdminPage() {
    if (admin) {
      return 'Accessing admin page!';
    }
    return 'No permissions to acess!';
  }
}

class Admin extends User{
  bool admin = true;
}


topLevelFunction() {
  return 'Calling top level function!';
}

var closureReflect = (String tmp) => print('Calling closure $tmp!');

getLibrary() {
  MirrorSystem mirrorSystem = currentMirrorSystem();
  return mirrorSystem.findLibrary(Symbol("server.main"));
}

Future main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // https://pub.dev/documentation/shelf/latest/shelf/Cascade-class.html
  final cascade = Cascade()
      .add(_router);

  // https://pub.dev/documentation/shelf/latest/shelf_io/serve.html
  final server = await shelf_io.serve(
    // https://pub.dev/documentation/shelf/latest/shelf/logRequests.html
    logRequests()
        // https://pub.dev/documentation/shelf/latest/shelf/MiddlewareExtensions/addHandler.html
        .addHandler(cascade.handler),
    InternetAddress.anyIPv4, // Allows external connections
    port,
  );

  print('Serving at http://${server.address.host}:${server.port}');
}

// Router instance to handler requests.
final _router = shelf_router.Router()
  ..get('/reflect', _reflectHandler)
  ..get('/reflect2', _reflect2Handler)
  ..get('/reflect3', _reflect3Handler)
  ..get('/reflect4', _reflect4Handler)
  ..get('/reflect5', _reflect5Handler)
  ..get('/reflect6', _reflect6Handler);

Response _reflectHandler(request) {
  var userInput = request.url.queryParameters['payload'];

  LibraryMirror libraryMirror = getLibrary();
  // Get Class and create a new object dynamically
  TypeMirror typeMirror = libraryMirror.declarations[Symbol(userInput)] as TypeMirror; // Sink Class reflection
  return Response.ok(MirrorSystem.getName(typeMirror.simpleName));
}

Response _reflect2Handler(request) {
  var userInput = request.url.queryParameters['payload'];

  InstanceMirror instanceMirror = reflect(User());
  // Call the admin getter dynamically
  InstanceMirror tmp = instanceMirror.getField(Symbol(userInput));  // Sink method reflection (getter)
  if (tmp.reflectee) {
    return Response.ok('Admin page!');
  }
  return Response.ok('Not allowed!');
}

Response _reflect3Handler(request) {
  var userInput = request.url.queryParameters['payload'];
  var userArgument = request.url.queryParameters['argument'];

  InstanceMirror instanceMirror = reflect(Admin());
  // Call the admin setter dynamically
  instanceMirror.setField(Symbol(userInput), userArgument);  // Sink method reflection (setter)
  InstanceMirror tmp = instanceMirror.getField(Symbol('username'));
  if (tmp.reflectee == 'admin') {
    return Response.ok('Admin page!');
  }
  return Response.ok('Not allowed!');
}

Response _reflect4Handler(request) {
  var userInput = request.url.queryParameters['payload'];

  ClassMirror classMirror = reflectClass(User().runtimeType);
  // Invoke class method dynamically 
  InstanceMirror tmp = classMirror.invoke(Symbol(userInput), []);  // Sink method reflection (InstanceMirror)
  return Response.ok(tmp.reflectee);
}

Response _reflect5Handler(request) {
  var userInput = request.url.queryParameters['payload'];

  LibraryMirror libraryMirror = getLibrary();
  // Get Class and create a new object dynamically
  TypeMirror typeMirror = libraryMirror.declarations[Symbol('User')] as TypeMirror;
  ClassMirror classMirror = typeMirror as ClassMirror;
  // Invoke static class method dynamically 
  InstanceMirror tmp = classMirror.invoke(Symbol(userInput), []);  // Sink method reflection (ClassMirror)
  return Response.ok(tmp.reflectee);
}

Response _reflect6Handler(request) {
  var userInput = request.url.queryParameters['payload'];

  LibraryMirror libraryMirror = getLibrary();
  print(libraryMirror.declarations);
  // Invoke top-level method dynamically 
  InstanceMirror tmp = libraryMirror.invoke(Symbol(userInput), []);  // Sink method reflection (LibraryMirror)
  return Response.ok(tmp.reflectee);
}

