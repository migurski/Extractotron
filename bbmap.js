// A Leaflet map to draw bounding boxes of the metros in Extractotron

function jsonXhr(url, success, error) {
    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState < 4) {
            return;
        }
        var s = req.status;
        if ((s >= 200 && s < 300) || s == 304) {
            var data = JSON.parse(req.responseText);
            success(data);
        } else {
            if (error) {
                error(req);
            } else {
                console.log("XHR error", req);
            }
        }
    };
    req.open('GET', url, true);
    req.send();
}

function makeBbMap() {
    // Create the leaflet base map
    var map = L.map('bbMap', {scrollWheelZoom: false});
    map.setView([20, 0], 2);
    var basemap = L.tileLayer('http://otile{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.jpg', {
            attribution: 'Tiles courtesy of <a href="http://www.mapquest.com/">MapQuest</a>, map data © <a href="http://www.openstreetmap.org/">OpenStreetMap</a>',
            maxZoom: 7,
            subdomains: '1234',
            noWrap: true,
    });
    basemap.addTo(map);

    // Load cities.json asynchronously
    jsonXhr('cities.json', function(cities) {
        // Render a box for each city, create the popup
        for (var i = 0; i < cities.length; i++) {
            var city = cities[i];
            var polygon = L.polygon([[city.b, city.r], [city.b, city.l],
                                     [city.t, city.l], [city.t, city.r]],
                                    { weight: 1.5, color: "#000",
                                     fillColor: "#82c", fillOpacity: 0.5 });
            var popupData = [
                '<a href="#' + city.slug + '">' + city.name + '</a>',
            ];
            polygon.bindPopup(popupData.join(''));
            polygon.addTo(map);
        }
    });
};
