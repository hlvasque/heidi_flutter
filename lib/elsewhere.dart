// Barrett Koster 2024
// demo of localizations
// https://localizely.com/blog/flutter-localization-step-by-step/?tab=using-gen-l10n

// > flutter pub add flutter_localizations --sdk=flutter
// > flutter pub add intl:any

// add to pubspec.yaml
// flutter:
//   generate:true 

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


void main() async
{ runApp(const ElseWhere());
}

class ElseWhere extends StatelessWidget 
{ const ElseWhere({super.key});

  @override
  Widget build(BuildContext context) 
  { return  MaterialApp
    ( 
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      title: 'ElseWhere',
      home:  ElseWhere1(),
    );
  }
}

class ElseWhere1 extends StatelessWidget 
{ const ElseWhere1({super.key});

  @override
  Widget build(BuildContext context)
  { 
    List<Widget> kids = 
    [ // BB("bob"),  BB("mary"), BB("jane"), 
      BB(AppLocalizations.of(context)!.helloWorld),
      Localizations.override
      ( context: context,
        locale: const Locale('es'),
        child: Builder // to get the context
        ( builder: (BuildContext context) {
            return BB(AppLocalizations.of(context)!.helloWorld);
          },
        ),
      ),
      Localizations.override
      ( context: context,
        locale: const Locale('ar'),
        child: Builder // to get the context
        ( builder: (BuildContext context) {
            return BB(AppLocalizations.of(context)!.helloWorld);
          },
        ),
      ),
    ];

    return Scaffold
    (
      appBar: AppBar( title: Text("LocalizeMe"),  ),
      body: Column( children: kids ),
    );
  }
}

class BB extends Container
{
  BB( String s ) : super
  ( decoration: BoxDecoration
    ( border: Border.all(width:2),),
    width:200, height:60,
    child: Text(s, style: const TextStyle(fontSize: 20) ),
  );
}