import 'dart:js' as js;

void requestWebLocationAsync() {
  js.context.callMethod('eval', ['''
    navigator.geolocation.getCurrentPosition(function(pos) {
      window.flutterLocationResult = {
        lat: pos.coords.latitude,
        lng: pos.coords.longitude
      };
    });
  ''']);
}

dynamic getWebLocationResultAsync() {
  final jsObj = js.context['flutterLocationResult'];
  if (jsObj != null) {
      double? lat;
      double? lng;
      try {
        lat = double.tryParse(jsObj['lat']?.toString() ?? '');
        lng = double.tryParse(jsObj['lng']?.toString() ?? '');
      } catch (_) {}
      
      if (lat != null && lng != null) {
          return {'lat': lat, 'lng': lng};
      }
  }
  return null;
}
