<?php

$envVars = getenv();

echo "+++ generate custom files" . PHP_EOL;
$allowedExtensions = ['json', 'txt'];

if(!empty($envVars["CUSTOMFILE_FETCHURL"])) {
    $ch = curl_init($envVars["CUSTOMFILE_FETCHURL"]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Authorization: Bearer $token"
    ]);

    $response = curl_exec($ch);

    if ($httpCode !== 200) {
        die("Error: HTTP $httpCode\nResponse:\n$response");
    }

    // JSON dekodieren
    $data = json_decode($response, true);    

    if (!is_array($data)) {
        die("invalid response: $response");
    }

    foreach ($data as $filename => $content) {

        // extract file extensions
        $extension = strtolower(pathinfo($filename, PATHINFO_EXTENSION));

        $filename = preg_replace("/[^0-9A-Za-z-_.]/", "", $filename);

        if (!in_array($extension, $allowedExtensions, true)) {
            echo "Skip (File extension not allowed): $filename\n";
            continue;
        }

        file_put_contents("/var/www/html/" . $filename, $content);
        echo "Created: $filename\n";
    }

}

$code = [];

foreach($envVars as $envVar => $value) {
    if(strpos($envVar, 'CUSTOMFILE_JSON_') === 0) {
        $filename = str_replace("CUSTOMFILE_JSON_", "", $envVar);
        $filename = strtolower($filename);
        $filename = preg_replace("/[^0-9a-z_]/", "", $filename);

        file_put_contents("/var/www/html/" . $filename . ".json", $value);
    }
}