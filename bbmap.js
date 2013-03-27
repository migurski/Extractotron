// A Leaflet map to draw bounding boxes of the metros in Extractotron

function makeBbMap()
{
    // Create the leaflet base map
    var map = L.map('bbMap', {scrollWheelZoom: false});
    map.setView([20, 0], 2);
    var basemap = L.tileLayer('http://otile{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.jpg', {
            attribution: 'Tiles courtesy of <a href="http://www.mapquest.com/">MapQuest</a>, map data © <a href="http://www.openstreetmap.org/">OpenStreetMap</a>',
            maxZoom: 7,
            subdomains: '1234',
            noWrap: false,
    });
    basemap.addTo(map);

    // Render a box for each city, create the popup
    for (var i = 0; i < cities.length; i++)
    {
        var city = cities[i],
            bounds = city['bounds'].split(/\s/).map(parseFloat);

        var polygon = L.polygon([[bounds[1], bounds[2]], [bounds[1], bounds[0]],
                                 [bounds[3], bounds[0]], [bounds[3], bounds[2]]],
                                { weight: 1.5, color: "#000",
                                 fillColor: "#82c", fillOpacity: 0.5 });
        var popupData = [
            '<b><a href="#' + city.slug + '">' + city.name + '</a></b><br>',
            city.area + '<br>',
            city.osm_size + " bzip’ed XML OSM data<br>",
            city.pbf_size + " binary PBF OSM data<br>",
            '<p>',
            '<a href="#' + city.slug + '"><img src="previews/' + city.slug + '.jpg" width="155" height="100"></a>',
        ];
        polygon.bindPopup(popupData.join(''));
        polygon.addTo(map);
    }
};
