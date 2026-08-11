import 'dart:convert';
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
      theme: ThemeData.dark(),
      home: StudioScreen(),
    );
  }
}

class StudioScreen extends StatefulWidget {
  @override
  _StudioScreenState createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  String themeName = "HyperOS 3 Orange";
  String designer = "Fouad";
  Color primary = Color(0xFFFF6900);
  bool loading = false;
  String msg = "";

  final List<Color> colors = [Color(0xFFFF6900), Color(0xFF00BCD4), Color(0xFF7C4DFF), Color(0xFF00E676), Color(0xFFFF1744), Color(0xFF2979FF)];

  Future<void> exportMTZ() async {
    setState(() { loading = true; msg = "جاري بناء الثيم uiVersion 17..."; });
    try {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();

      String xml = '''<?xml version="1.0" encoding="utf-8"?>
<MIUI-Theme>
  <title>$themeName</title>
  <designer>$designer</designer>
  <author>$designer</author>
  <version>3.0</version>
  <uiVersion>17</uiVersion>
  <is3rdParty>1</is3rdParty>
</MIUI-Theme>''';

      List<int> xmlBytes = utf8.encode(xml);
      // صورة بيضاء 1x1 كـ preview عشان الـ MTZ يتقبل
      List<int> dummyJpg = base64Decode('/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBxISEhUSEhIVFhUVFRUVFRUVFRUVFRUWFhUVFRUYHSggGBolGxUVITEhJSkrLi4uFx8zODMtNygtLisBCgoKDg0OGxAQGy0mICUtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLf/AABEIAMwAigMBIgACEQEDEQH/xAAVAAEBAAAAAAAAAAAAAAAAAAAAB//EABQQAQAAAAAAAAAAAAAAAAAAAAD/xAAUAQEAAAAAAAAAAAAAAAAAAAAA/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AVQA//9k=');

      Archive arch = Archive();
      arch.addFile(ArchiveFile('description.xml', xmlBytes.length, xmlBytes));
      arch.addFile(ArchiveFile('preview.jpg', dummyJpg.length, dummyJpg));
      arch.addFile(ArchiveFile('wallpaper', dummyJpg.length, dummyJpg));

      List<int>? zipBytes = ZipEncoder().encode(arch);
      if (zipBytes == null) throw Exception("ZipEncoder فشل");

      Directory temp = await getTemporaryDirectory();
      String fileName = "${themeName.replaceAll(' ', '_')}.mtz";
      String tempPath = "${temp.path}/$fileName";
      await File(tempPath).writeAsBytes(zipBytes);

      String downloadPath = "/storage/emulated/0/Download/$fileName";
      try {
        await File(downloadPath).writeAsBytes(zipBytes);
        setState(() { msg = "✅ تم التصدير! \n$downloadPath"; });
      } catch (e) {
        setState(() { msg = "✅ تم التصدير! \n$tempPath\n(انسخه لـ Download يدوياً)"; });
        downloadPath = tempPath;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم حفظ الثيم في Download"), backgroundColor: primary));
    } catch (e) {
      setState(() { msg = "❌ خطأ: $e"; });
    } finally {
      setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0C),
      appBar: AppBar(backgroundColor: primary, title: Text("HyperOS 3 Studio", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معاينة الموبايل
            Center(
              child: Container(
                width: 200, height: 360,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30), border: Border.all(color: primary, width: 3)),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    CircleAvatar(backgroundColor: primary, radius: 30, child: Icon(Icons.palette, color: Colors.black)),
                    SizedBox(height: 15),
                    Text(themeName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    Text(designer, style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Spacer(),
                    Container(height: 50, decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.vertical(bottom: Radius.circular(27))), child: Center(child: Text("HyperOS 3", style: TextStyle(color: Colors.black)))),
                  ],
                ),
              ),
            ),
            SizedBox(height: 25),
            Text("اسم الثيم", style: TextStyle(color: Colors.white54)),
            TextField(onChanged: (v)=>setState(()=>themeName=v), controller: TextEditingController(text: themeName), style: TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            SizedBox(height: 12),
            Text("اسم المصمم", style: TextStyle(color: Colors.white54)),
            TextField(onChanged: (v)=>designer=v, controller: TextEditingController(text: designer), style: TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            SizedBox(height: 20),
            Text("لون الثيم", style: TextStyle(color: Colors.white54)),
            SizedBox(height: 8),
            Row(children: colors.map((c)=>GestureDetector(onTap: ()=>setState(()=>primary=c), child: Container(margin: EdgeInsets.only(right: 10), width: 40, height: 40, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: primary==c? Colors.white: Colors.transparent, width: 2))))).toList()),
            SizedBox(height: 20),
            Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.verified, color: primary), SizedBox(width: 10), Text("uiVersion 17 - HyperOS 3 Ready", style: TextStyle(color: Colors.white70))])),
            SizedBox(height: 20),
            if(msg.isNotEmpty) Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Text(msg, style: TextStyle(color: Colors.greenAccent))),
            SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), onPressed: loading? null : exportMTZ, child: loading? CircularProgressIndicator(color: Colors.black) : Text("تصدير .mtz الآن", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
            SizedBox(height: 10),
            Center(child: Text("هيتحفظ في Download > ثبته من تطبيق الثيمات > استيراد", style: TextStyle(color: Colors.white30, fontSize: 11))),
          ],
        ),
      ),
    );
  }
}
