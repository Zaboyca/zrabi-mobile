import 'package:flutter/material.dart';

/// Material stand-ins for web `<x-category-icon>` by category slug.
IconData categoryIconForSlug(String? slug) {
  switch (slug) {
    case 'remont-i-stroitelstvo':
      return Icons.handyman_outlined;
    case 'uborka':
      return Icons.home_outlined;
    case 'krasota':
      return Icons.spa_outlined;
    case 'repetitory':
      return Icons.menu_book_outlined;
    case 'it-i-dizain':
      return Icons.laptop_mac_outlined;
    case 'avto':
      return Icons.directions_car_outlined;
    case 'zdorove':
      return Icons.favorite_border;
    case 'remont-texniki':
      return Icons.phone_iphone_outlined;
    case 'kurery-i-perevozki':
      return Icons.local_shipping_outlined;
    case 'iuristy-i-buxgaltery':
      return Icons.balance_outlined;
    case 'zivotnye':
      return Icons.pets_outlined;
    case 'sad-i-uchastok':
      return Icons.yard_outlined;
    case 'sportivnye-trenery':
      return Icons.fitness_center_outlined;
    case 'foto-i-video':
      return Icons.photo_camera_outlined;
    case 'meropriiatiia':
      return Icons.music_note_outlined;
    case 'ischete-kogo-to-eshche':
      return Icons.search;
    default:
      return Icons.grid_view_outlined;
  }
}
