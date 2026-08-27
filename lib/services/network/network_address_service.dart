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
        if (_isPrivate(address.address)) {
          addresses.add(address.address);
        }
      }
    }
    // Fallback: if we filtered out everything, just add them all back
    if (addresses.isEmpty) {
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (_isPrivate(address.address)) {
            addresses.add(address.address);
          }
        }
      }
    }
    final sorted = addresses.toList()..sort((a, b) {
      // Prioritize 192.168.* (score 2) and 10.* (score 1) over 172.* (score 0)
      final scoreA = a.startsWith('192.168.') ? 2 : a.startsWith('10.') ? 1 : 0;
      final scoreB = b.startsWith('192.168.') ? 2 : b.startsWith('10.') ? 1 : 0;
      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA);
      }
      return a.compareTo(b);
    });
    return sorted;
  }

  bool _isPrivate(String address) {
    final octets = address.split('.').map(int.tryParse).toList();
    if (octets.length != 4 || octets.any((value) => value == null)) {
      return false;
    }
    final first = octets[0]!;
    final second = octets[1]!;
    return first == 10 ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168);
  }
}
