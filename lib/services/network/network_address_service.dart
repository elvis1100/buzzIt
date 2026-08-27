import 'dart:io';

class NetworkAddressService {
  Future<List<String>> findLocalIpv4Addresses() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    final addresses = <String>{};
    for (final interface in interfaces) {
      final name = interface.name.toLowerCase();
      // Skip common virtual/docker interfaces
      if (name.contains('docker') ||
          name.contains('vbox') ||
          name.contains('vmnet') ||
          name.startsWith('br-') ||
          name.startsWith('veth')) {
        continue;
      }
      for (final address in interface.addresses) {
        addresses.add(address.address);
      }
    }
    // Preserve a usable manual option on systems with only virtual adapters.
    if (addresses.isEmpty) {
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          addresses.add(address.address);
        }
      }
    }
    final sorted = addresses.toList()
      ..sort((a, b) {
        final scoreA = _addressScore(a);
        final scoreB = _addressScore(b);
        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA);
        }
        return a.compareTo(b);
      });
    return sorted;
  }

  int _addressScore(String address) {
    final octets = address.split('.').map(int.tryParse).toList();
    if (octets.length != 4 || octets.any((value) => value == null)) {
      return 0;
    }
    final first = octets[0]!;
    final second = octets[1]!;
    if (first == 192 && second == 168) {
      return 4;
    }
    if (first == 10) {
      return 3;
    }
    if (first == 172 && second >= 16 && second <= 31) {
      return 2;
    }
    if (first == 100 && second >= 64 && second <= 127) {
      return 1;
    }
    return 0;
  }
}
