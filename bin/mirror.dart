import "dart:async";
import "dart:convert";
import "dart:io";

import "package:legit/legit.dart";

class Mirror {
  final String name;
  final String source;
  final String target;

  const Mirror(this.name, this.source, this.target);
}

bool verbose = false;

main() async {
  GitClient.handleConfigure(handle, logHandler: handleMessage);

  Stream<String> lines = stdin
    .transform(const Utf8Decoder())
    .transform(const LineSplitter());

  await for (String line in lines) {
    if (line == "verbose") {
      verbose = true;
    } else if (line == "quiet") {
      verbose = false;
    }
  }
}

handleMessage(String msg) {
  if (verbose) {
    print(msg);
  }
}

handle() async {
  while (true) {
    var mirrors = await loadMirrorList();
    for (Mirror mirror in mirrors) {
      var git = await GitClient.openOrCloneRepository(
        mirror.source,
        "mirrors/${mirror.name}",
        mirror: true
      );

      if (!(await git.hasRemote("target"))) {
        await git.addRemote("target", mirror.target);
      }

      await git.fetch(remote: "origin");
      await git.push(remote: "target", mirror: true);
    }

    await new Future.delayed(const Duration(seconds: 10));
  }
}

Future<List<Mirror>> loadMirrorList() async {
  var file = new File("mirrors.json");
  if (!(await file.exists())) {
    await file.writeAsString("{}");
  }
  var content = await file.readAsString();
  var mirrors = <Mirror>[];
  Map<String, Map<String, dynamic>> map = const JsonDecoder().convert(content);
  for (var key in map.keys) {
    var a = map[key];
    var m = new Mirror(key, a["source"], a["target"]);
    mirrors.add(m);
  }
  return mirrors;
}

