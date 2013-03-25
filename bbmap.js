// A Leaflet map to draw bounding boxes of the metros in Extractotron

function makeBbMap() {
    var map = L.map('bbMap');
    map.setView([20, 0], 2);
    var basemap = L.tileLayer('http://otile{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.jpg', {
            attribution: 'Tiles courtesy of <a href="http://www.mapquest.com/">MapQuest</a>, map data © <a href="http://www.openstreetmap.org/">OpenStreetMap</a>',
            maxZoom: 7,
            subdomains: '1234',
            noWrap: true,
    });
    basemap.addTo(map);

    d3.tsv('cities.txt', function(cities) {
        for (var i = 0; i < cities.length; i++) {
            var city = cities[i];
            var t = parseFloat(city.top),
                b = parseFloat(city.bottom),
                l = parseFloat(city.left),
                r = parseFloat(city.right);
            var polygon = L.polygon([[b,r], [b,l], [t,l], [t, r]],
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
