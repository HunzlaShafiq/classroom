import 'package:classroom/Providers/classroom_provider.dart';
import 'package:classroom/Providers/profile_provider.dart';
import 'package:provider/provider.dart';

class LogoutLoginServices{


  void logoutRemoveData(context){

    Provider.of<ClassroomProvider>(context,listen: false).removeDataOnLogout();
    Provider.of<ProfileProvider>(context,listen: false).removeDataOnLogout();

  }

  void loginRefreshData(context){

    Provider.of<ClassroomProvider>(context,listen: false).refreshDataOnLogin();
    Provider.of<ProfileProvider>(context,listen: false).removeDataOnLogout();

  }




}