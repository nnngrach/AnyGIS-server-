<?xml version="1.0" encoding="utf-8"?>

<customMapSource>
<name>Yandex Satellite + labels</name>
<layers>

<layer>
    <minZoom>0</minZoom>
    <maxZoom>19</maxZoom>
    <url>https://anygis.herokuapp.com/Yandex_sat_clean/{$x}/{$y}/{$z}</url>
</layer>

<layer>
    <minZoom>0</minZoom>
    <maxZoom>19</maxZoom>
    <url>https://anygis.herokuapp.com/Yandex_sat_labels/{$x}/{$y}/{$z}</url>
</layer>

</layers>
</customMapSource>