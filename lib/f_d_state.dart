// f_d_state.dart
// Barrett Koster 2025
// demo of HydratedBloc (HydratedCubit)

import 'dart:convert';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class FDState
{ 
  String food;

  FDState(this.food);

  // turns the object into a map
  Map<String,dynamic> toMap()
  { return
    { 'food' : food ,
    };
  } 
  
  // turn a map back into an object
  factory FDState.fromMap(Map<String,dynamic> map)
  {
    return FDState( map['food'] );
  }

  // turns the object into JSON.  Does this by 
  // call toMap and then encode() ing the map.
  String toJson() => json.encode(toMap);

  // turns Json back into an objevct.  
  factory FDState.fromJson( String source) 
  => FDState.fromMap( json.decode(source));
   
}

class FDCubit extends HydratedCubit<FDState> // with HydratedMixin
{
  FDCubit() : super( FDState("banana") );

  void setFood(String f ) { emit( FDState(f) ); }

  // converts the map form of FDState into an object.
  // Should have been called fromMap, as the Hydrated stuff
  // will have already converted it from JSON to a map.
  @override
  FDState fromJson( Map<String,dynamic> map)
  { return FDState.fromMap(map); }

  // This is called on state AFTER emit(state).  Every time there is a new
  // state, this function converts it to a Map and the Hydrated
  // stuff takes it from there.  
  @override
  Map<String,dynamic> toJson( FDState state )
  { return state.toMap(); }
}

