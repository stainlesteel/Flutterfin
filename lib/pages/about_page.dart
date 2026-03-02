import 'package:flutter/material.dart';
import 'package:jellyfin/main.dart';
import 'package:jellyfin/comps/comps.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    Widget scaffold = Scaffold(
      appBar: AppBar(title: Text('About $appTitle'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(appTitle, style: getTextStyling(0, context)),
              SizedBox(height: 5,),
              FilledButton.tonal(
                onPressed: () {}, 
                child: Text('Development', style: getTextStyling(4, context),),
              ),
              SizedBox(height: 5,),
              simpleTile(
                title: 'Report an Issue',
                trailing: Icon(Icons.link),
                onTap: () {
                  showScaffold('no url yet', context);
                },
              ),
              SizedBox(height: 30),
              simpleTile(
                title: 'Credits',
                onTap: () {
                  SimpleErrorDiag(
                    title: 'Credits', 
                    desc: 'Created by stainlesteel.\ncopyright information is defined by Apache License 2.0.', 
                    context: context
                  );
                },
              ),
              simpleTile(
                title: 'License Info',
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: appTitle,
                    applicationVersion: 'in Development',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    return scaffold;
  }
}
