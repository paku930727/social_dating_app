import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:social_dating_app/application/maps/maps_state.dart';
import 'package:social_dating_app/domain/feed/feed_user_model.dart';
import 'package:social_dating_app/domain/location/user_location_model.dart';
import 'package:social_dating_app/providers/firebase/firebase_provider.dart';
import 'package:geolocator/geolocator.dart';

class MapsStateNotifier extends StateNotifier<MapsState> {
  MapsStateNotifier(this._read) : super(MapsState.empty());

  final Reader _read;
  final Completer<GoogleMapController> _controller = Completer();

  Future<void> getUsersMarkers() async {
    final firestore = _read(firestoreProvider);
    /*   using where() method, and "uid" in below, you can filter current user.
      
          final uid = _read(authRepositoryProvider).getCurrentUser()!.uid;

          final getUsersFromFirestore = await firestore.collection("users")
          .where("uid", isNotEqualTo: uid).get();
    */
    final getUsersFromFirestore = await firestore.collection("users").get();
    final Set<Marker> markerList = {};
    final List<FeedUserModel> usersInFeed = [];

    getUsersFromFirestore.docs.map((e) => e.data()).toList().forEach(
      (element) {
        markerList.add(
          Marker(
            position: LatLng(
              element["latitude"],
              element["longitude"],
            ),
            markerId: MarkerId(
              element["uid"],
            ),
            infoWindow: InfoWindow(
              title: element["userName"],
            ),
            onTap: () async {
              final controller = await _controller.future;
              controller.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    zoom: 18,
                    target: LatLng(
                      element["latitude"],
                      element["longitude"],
                    ),
                  ),
                ),
              );
            },
          ),
        );
        usersInFeed.add(
          FeedUserModel(
            imageUrl: element["imageURL"],
            status: element["status"],
            userName: element["userName"],
          ),
        );
      },
    );
    print(markerList);
    state = state.copyWith(
      markerList: markerList,
      usersInFeed: usersInFeed,
    );
  }

  Future<void> getCurrentPosition() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then(
      (Position currentPosition) {
        final latValueOfTheCurrentPosition = currentPosition.latitude;
        final longValueOfTheCurrentPosition = currentPosition.longitude;
        final uid = _read(authRepositoryProvider).getCurrentUser()!.uid;
        final firestore = _read(firestoreProvider);

        firestore.collection("users").doc(uid).set(
          {
            'latitude': latValueOfTheCurrentPosition,
            'longitude': longValueOfTheCurrentPosition,
          },
          SetOptions(merge: true),
        );

        state = state.copyWith(
          currentUserLocation: UserLocationModel(
            latOfCurrentLocation: latValueOfTheCurrentPosition,
            longOfCurrentLocation: longValueOfTheCurrentPosition,
          ),
        );
      },
    );
  }

  Future<void> getCurrentPositionWithUserPermission() async {
    await Geolocator.checkPermission().then(
      (LocationPermission locationPermission) async {
        if (locationPermission == LocationPermission.denied ||
            locationPermission == LocationPermission.deniedForever ||
            locationPermission == LocationPermission.unableToDetermine) {
          await Geolocator.requestPermission().then(
            (LocationPermission requestPermission) async {
              if (requestPermission == LocationPermission.denied ||
                  requestPermission == LocationPermission.deniedForever ||
                  requestPermission == LocationPermission.unableToDetermine) {
                state = state.copyWith(
                  locationPermission: LocationPermission.denied,
                );
              } else {
                state = state.copyWith(
                  locationPermission: requestPermission,
                );

                getCurrentPosition();
              }
            },
          );
        } else {
          state = state.copyWith(
            locationPermission: locationPermission,
          );

          getCurrentPosition();
        }
      },
    );
  }
}
