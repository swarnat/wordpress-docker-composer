<?php

$envVars = getenv();

echo "+++ generate wp-config.php" . PHP_EOL;

$code = [];

foreach($envVars as $envVar => $value) {
    if(strpos($envVar, 'WP_') === 0) {
        $constant = substr($envVar, 3);

        if(is_numeric($value)) {
            $code[] = "define( '".$constant."', ".$value." );";
        } elseif($value == 'true') {
            $code[] = "define( '".$constant."', true );";
        } elseif($value == 'false') {
            $code[] = "define( '".$constant."', false );";
        } else {
            $code[] = "define( '".$constant."', '".$value."' );";
        }
        
    }
}

$code[] = '$table_prefix = "wp_";';

$code[] = <<<'END'
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && 
    strpos($_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false
) {
    $_SERVER['HTTPS'] = 'on';
}

$_SERVER['HTTPS'] = 'off';

// Disable setup of files
define('DISALLOW_FILE_MODS',true);

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
END;

file_put_contents('/var/www/html/wp-config.php', '<?php ' . PHP_EOL . implode(PHP_EOL, $code) . PHP_EOL);

echo "+++ OK" . PHP_EOL;