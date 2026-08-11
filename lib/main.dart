import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(HyperOS3App());

class HyperOS3App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF0A0A0C),
        primaryColor: Color(0xFFFF6900),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String themeName = "HyperOS 3 Orange";
  String designer = "Fouad";
  Color primaryColor = Color(0xFFFF6900);
  bool isExporting = false;
  String status = "";

  Future<void> exportMTZ() async {
    setState(() { isExporting = true; status = "جاري إنشاء الثيم..."; });
    try {
      var perm = await Permission.storage.request();
      if (!perm.isGranted) {
        await Permission.manageExternalStorage.request();
      }

      final dir = await getTemporaryDirectory();
      final themeDir = Directory('${dir.path}/theme');
      if (await themeDir.exists()) await themeDir.delete(recursive: true);
      await themeDir.create();

      String descriptionXml = '''<?xml version="1.0" encoding="utf-8"?>
<MIUI-Theme>
    <title>$themeName</title>
    <designer>$designer</designer>
    <author>$designer</author>
    <version>3.0</version>
    <uiVersion>17</uiVersion>
    <wallpaperDepth>0</wallpaperDepth>
</MIUI-Theme>''';

      await File('${themeDir.path}/description.xml').writeAsString(descriptionXml);
      await File('${themeDir.path}/preview.jpg').writeAsBytes(Uint8List(0));
      await File('${themeDir.path}/wallpaper').create();

      final archive = Archive();
      final files = await themeDir.list().toList();
      for (var f in files) {
        if (f is File) {
          var bytes = await f.readAsBytes();
          var name = f.path.split('/').last;
          if (name == 'wallpaper') {
             // create a simple orange wallpaper bytes placeholder
             archive.addFile(ArchiveFile('wallpaper', 0, []));
          } else {
             archive.addFile(ArchiveFile(name, bytes.length, bytes));
          }
        }
      }

      var zipData = ZipEncoder().encode(archive);
      if (zipData == null) throw Exception("فشل الضغط");

      final downloads = Directory('/storage/emulated/0/Download');
      if (!await downloads.exists()) {
        await Directory('${dir.path}/Download').create();
      }
      String outPath = '/storage/emulated/0/Download/${themeName.replaceAll(' ', '_')}.mtz';
      try {
        await File(outPath).writeAsBytes(zipData);
      } catch (e) {
        outPath = '${dir.path}/${themeName}.mtz';
        await File(outPath).writeAsBytes(zipData);
      }

      setState(() { status = "تم! الملف في: $outPath"; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم تصدير $outPath")));
    } catch (e) {
      setState(() { status = "خطأ: $e"; });
    } finally {
      setState(() { isExporting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HyperOS 3 Studio"), backgroundColor: Color(0xFFFF6900)),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),
            Icon(Icons.color_lens, size: 80, color: primaryColor),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(labelText: "اسم الثيم", border: OutlineInputBorder()),
              onChanged: (v) => themeName = v,
              controller: TextEditingController(text: themeName),
            ),
            SizedBox(height: 15),
            TextField(
              decoration: InputDecoration(labelText: "اسم المصمم", border: OutlineInputBorder()),
              onChanged: (v) => designer = v,
              controller: TextEditingController(text: designer),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: primaryColor, radius: 20),
                  SizedBox(width: 12),
                  Text("uiVersion 17 - HyperOS 3 Ready", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            Spacer(),
            if (status.isNotEmpty) Text(status, style: TextStyle(color: Colors.greenAccent)),
            SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF6900), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                onPressed: isExporting ? null : exportMTZ,
                child: isExporting ? CircularProgressIndicator(color: Colors.white) : Text("تصدير .mtz الآن", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 10),
            Text("الملف هيتحفظ في Download وبيتثبت من تطبيق الثيمات > استيراد", style: TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
