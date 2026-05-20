import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:provider/provider.dart';
import 'package:jellyfin/comps/comps.dart';
import 'package:jellyfin/providers/providers.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:convert';

Widget brandingImage(String url, BuildContext context,) {
  final Size size = MediaQuery.sizeOf(context);
  double heightMultipler = 0.45;
  double widthMultipler = (size.width > 1100)
  ? 0.5
  : 0.7;

  return SizedBox(
    height: MediaQuery.heightOf(context) * heightMultipler,
    width: MediaQuery.widthOf(context) * widthMultipler,
    child: Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (context, url, child) {
        return Text('Image unavailable');
      },
    ),
  );
}

class BrandingPage extends StatefulWidget {
  const BrandingPage({super.key});

  @override
  State<BrandingPage> createState() => _BrandingPageState();
}

class _BrandingPageState extends State<BrandingPage> {
  BrandingOptionsDto? brandingOptions;
  bool loaded = false;

  late JellyfinAPI ama = context.read<JellyfinAPI>();
  late String url =  '${ama.serverList[ama.lastUsedServer!].serverURL}/Branding/SplashScreen';

  @override
  void initState() {
    super.initState();
    starter();
  }

  Future<void> starter() async {
    final data = await Provider.of<JellyfinAPI>(context, listen: false).getBrandingOptions();

    setState(() {
      brandingOptions = data;
      loaded = true;
    });
  }
   
  @override
  Widget build(BuildContext context) {
    JellyfinAPI ama = context.watch<JellyfinAPI>();
    Size size = MediaQuery.sizeOf(context);

    Widget getChildren() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EasyTile(
            title: Text('Enable splash screen image', style: getTextStyling(4, context)),
            trailing: SizedBox(
              width: 40,
              child: Switch(
                value: brandingOptions!.splashscreenEnabled!,
                onChanged: (bool gabagool) async {
                  setState(() {
                    brandingOptions = brandingOptions!.copyWith(
                      splashscreenEnabled: gabagool,
                    );
                  });
                  await ama.updateBrandingConfiguration(brandingOptions!);
                },
              ),
            ),
            context: context,
          ),
          SizedBox(height: 5),
          Text('Custom images should be in 16x9 aspect ratio and a minimum resolution of 1920x1080'),
          SizedBox(height: 5),
          FloatingActionButton.extended(
            onPressed: brandingOptions!.splashscreenEnabled!
            ? () async {
              await ama.deleteCustomSplashscreen();
              setState(() {
                url = '${ama.serverList[ama.lastUsedServer!].serverURL}/Branding/SplashScreen';
              });
            }
            : null,
            icon: Icon(Icons.delete),
            label: Text('Delete Custom Image'),
            backgroundColor: Colors.red,
          ),
        ],
      );
    }


    return Scaffold(
      body: SingleChildScrollView(
        child: loaded 
        ? Column(
          children: [
            Text('Branding', style: getTextStyling(2, context)),
            Text('This is the login screen branding for Jellyfin, works on any Web-based client and custom clients that support them.'),
            SizedBox(height: 5),
            (size.width > 1100)
            ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (brandingOptions!.splashscreenEnabled!)
                  brandingImage(url, context)
                else
                  Text('Image disabled'),
                Flexible(child: getChildren()),
              ],
            )
            : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (brandingOptions!.splashscreenEnabled!)
                  brandingImage(url, context)
                else
                  Text('Image disabled'),
                Flexible(child: getChildren()),
              ],
            ),
          ],
        )
        : CircularProgressIndicator(),
      ),
    );
  }
}
