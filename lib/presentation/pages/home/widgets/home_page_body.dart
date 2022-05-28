import 'package:flutter/material.dart';
import 'package:social_dating_app/presentation/pages/home/widgets/custom_list_tile.dart';

class HomePageBody extends StatelessWidget {
  const HomePageBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemCount: 4,
        itemBuilder: (context, index) {
          return const CustomListTile(
            userImageUrl: "https://picsum.photos/200/300",
            userStatus: "userStatus",
            userName: "userName",
            podcastOwnersName: "podcastOwnersName",
          );
        });
  }
}
