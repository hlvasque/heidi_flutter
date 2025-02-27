// routes2.dart
// Barrett Koster
// demo of Routing/Navigation.
// This one does the routing with NAMED routes.
// We provide the ONE CounterCubit before we even
// do the first MaterialApp, to make the Cubit available
// to all below.  The MaterialApp has a 'routes' 
// property where you can specify Routes/pages.  Note that
// each of the pages/Routes is a MaterialPageRoute, which
// means that the CounterCubit access will NOT be passed
// down through context.  So we need to get the CounterCubit 
// from the context before we are down in the
// context of the new MaterialPageRoute (but of course it
// has to AFTER we make it).  The line
// { "/" : (con) 
// is the right place, the function that is making the
// new MaterialPageRoute from the exiting context 'con'.
// In the routes.dart version, we pass the cc as an 
// argument to the Route, but here, by doing the BlocProvider
// with the RouteX as a child, we establish the Cubit
// just inside the top of the new MaterialPageRoute.
// Note that we use the ".value" form of the BlocProvider
// to use the cc that we just fetch, not make a new Cubit.
// Oh, one more thing: use the "Navigator .... pushNamed" 
// form of the push command to use the named routes.  Oh,
// and the first one has to be "/".  Since there is no "home:"
// any more, this is the default.

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

TextStyle ts = TextStyle(fontSize: 30);

class CounterState
{ int count;
  CounterState( this.count );
}
class CounterCubit extends Cubit<CounterState>
{
  CounterCubit() : super( CounterState(0) );

  void inc() { emit( CounterState(state.count+1) ); }
}

void main()
{ runApp( RoutesDemo() ); }

class RoutesDemo extends StatelessWidget
{
  RoutesDemo({super.key});

  @override
  Widget build( BuildContext context )
  { String title = "Routes Demo";
    return BlocProvider<CounterCubit>
    ( create: (context) => CounterCubit(),
      child:  MaterialApp
      ( title: title,
        routes: 
        { "/" : (con) 
                { CounterCubit cc = BlocProvider.of<CounterCubit>(con);
                  return BlocProvider<CounterCubit>.value
                  ( value: cc,
                    child: Route1(),
                  );
                },
          "p2": (con)
                { CounterCubit cc = BlocProvider.of<CounterCubit>(con);
                  return  BlocProvider<CounterCubit>.value
                  ( value: cc, 
                    child: Route2(), 
                  );
                },
        },
        // home: TopBloc()
      ),
    );
  }
}

class Route1 extends StatelessWidget
{ final String title = "Route1";

  @override
  Widget build( BuildContext context )
  { return BlocBuilder<CounterCubit,CounterState>
    ( builder: (context,state)
      { CounterCubit cc = BlocProvider.of<CounterCubit>(context);
        return  Scaffold
        ( appBar: AppBar( title: Text( title, style: ts) ),
          body: Column
          ( children: 
            [ Text("page 1", style:ts),
              Text("${cc.state.count}",style:ts),
              ElevatedButton
              ( onPressed: () { cc.inc(); },
                child: Text("add 1",style:ts),
              ),
              ElevatedButton
              ( onPressed: ()
                { Navigator.of(context).pushNamed("p2"); },
                child: Text("go to page 2", style:ts),
              ),
            ],
          ),
        );
      },
    );
  }
}

class Route2 extends StatelessWidget
{ final String title = "Route2";

  @override
  Widget build( BuildContext context )
  { return BlocBuilder<CounterCubit,CounterState>
    ( builder: (context,state)
      { CounterCubit cc = BlocProvider.of<CounterCubit>(context);
        return Scaffold
        ( appBar: AppBar( title: Text( title, style: ts) ),
          body: Column
          ( children: 
            [ Text("page 2", style:ts),
              Text("${cc.state.count}",style:ts),
              ElevatedButton
              ( onPressed: (){ cc.inc(); },
                child: Text("add 1", style:ts),
              ),
              ElevatedButton
              ( onPressed: (){ Navigator.of(context).pop(); },
                child: Text("go back",style:ts),
              ),
            ],
          ),
        );
      },
    );
  }
}


