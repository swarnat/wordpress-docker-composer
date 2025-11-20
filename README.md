# Stateless Wordpress Docker Image

This Docker Image was created to hold and keep stateless Wordpress Systems, based on Composer.  
If you don't need stateless, composer based, wordpress deployment, there are much better images available.  

## So what is the purpose of this image?

The typical hosting of Wordpress is statefull, because you have media files, plugins etc. stored locally. This means, your installation have a "*custom state*".  
With https://wpackagist.org/ and Docker image **johnpbloch/wordpress**, there are better and more flexible ways to create Wordpress deployments.  
They both provide a definition method of a defined wordpress system, including Theme and Plugins, which can be reconstructed at any time.  

## Why not use Bedrock?

[Bedrock](https://roots.io/bedrock/) is a boilerplate, which fullfill almost the same target, also when stateless deployment is only a side effect. And this is working great, because they optimize some wordpress functions and the way, how the directory structure of wordpress is created.  

**So, why not using it?**  
Basically, because of an additional requirement I was set myself. Because when this image is used by wordpress agencies, which also provide hosting form customers, these customers can ask to transfer a website to some other hosting providers.   
When a customer ask for this and get something customized it isn't easy to use and adjustable for other companies. So I wanted to keep the file structure as original as possible.  
And one big side effect is, that wp-admin is opened over **/wp/wp-admin**, which makes is confuse default developers, which also works on original deployment situation.

## What happens with media files?

Now we have a deployment, which can be reconstructed with the help of composer, we now must make sure, also media files are not stored locally.  
There are many powerfull plugins for this use case, which often use AWS, Google Cloud, DigitalOcean, etc. to store files. Because of GDPR, this often is a big discussion in germany, to use such providers. And often custom S3 hosters, of MinIO instances are used. That's why the plugin must provide a custom S3 configuration, which often is only used after monthly payments / subscription of license fees for plugins.  
I don't need 70% of these plugins and normally also don't need a configuration UI, because it is used only automated. And so I implemented a small plugin, called "[wp-s3-offload](https://packagist.org/packages/swarnat/wp-s3-offload)" myself, which store files on any S3 storage. Currently not available over wordpress.org store, but [fully open source](https://github.com/swarnat/wp-s3-offloading).  
When this plugin is configured, any media file can be stored and integrated remotely by using a S3 bucket.  
But to be honest: Every one of these plugins is working great:
  - https://de.wordpress.org/plugins/ilab-media-tools/
  - https://de.wordpress.org/plugins/amazon-s3-and-cloudfront/
  - https://de.wordpress.org/plugins/wp-s3-smart-upload/
  - https://de.wordpress.org/plugins/upcasted-s3-offload/
  - *... much more*

## Configuration

The environment variable **CUSTOMFILE_FETCHURL** can be used to set an URL to fetch custom files, which are placed within the container.  
The response should be a JSON in the following structure:  
{"composer.json": "{ ... Composer definition ... }", "velocita.json": "{ ... velocita configuration ... }"}  

**You can only fetch \*.json, \*.txt and \*.lock Files.**  

This FETCHURL endpoint can be secured by using a Bearer Token. This should be set into **CUSTOMFILE_FETCHURL_BEARER** envirobnment variable.  

### Custom files per environment

You can also set environment variables like: **CUSTOMFILE_JSON_COMPOSER**  and define the composer.json within this environment variable.  
The filename is stored after "CUSTOMFILE_JSON_" and converted into lowercase and extended by ".json".  

This gives you multiple ways to prevent using file mounts.

## custom file mounts

You can also mount custom files into the container, like the composer.json:

```json
{
    "repositories": [
        {
          "type": "composer",
          "url": "https://wpackagist.org",
          "only": [
            "wpackagist-plugin/*",
            "wpackagist-theme/*"
          ]
        }
    ],    
    "extra": {
        "wordpress-install-dir": "html",
        "installer-paths": {
            "html/wp-content/mu-plugins/{$name}/": [
                "type:wordpress-muplugin"
            ],
            "html/wp-content/plugins/{$name}/": [
                "type:wordpress-plugin"
            ],
            "html/wp-content/themes/{$name}/": [
                "type:wordpress-theme"
            ]
        }
    },
    "require": {
        "johnpbloch/wordpress": "^6.2",
        
        "swarnat/wp-s3-offload":"0.8.0",
        "wpackagist-plugin/wp-mail-smtp":"3.8.0"
    },
    "config": {
        "allow-plugins": {
            "johnpbloch/wordpress-core-installer": true,
            "isaac/composer-velocita": true,
            "composer/installers": true
        }
    }
}

```

The important part is shown within repositories, because the registration of WPackagist is done, which hold almost all default wordpress plugins as composer package. I would recommend to also add the listed plugins **"swarnat/wp-s3-offload"** and **"wpackagist-plugin/wp-mail-smtp"**, because this handle the stateless storage of media files and smtp mail sending. It should be default, but unfortunatelly isn't to send mails encrypted over SMTP. The following commands expect, that you had enabled them.  
I choose "[WP Mail SMTP](https://de.wordpress.org/plugins/wp-mail-smtp/)" from WPForms, because it can configured fully automated.  

## Wordpress Configuration

In Wordpress often everything is configured with constants in wp-config.php file and this image also use this way.  
All environment variables, you define in Docker container, which have prefix WP_ will be written, without this prefix, into wp-config.php. So you can provide an automated configuration for any plugin you use.  

```sh
docker run --rm --name wordpress -it -p 8580:8080 \
    -e WP_DB_HOST=db-host \
    -e WP_DB_NAME=db-name \
    -e WP_DB_USER=db-user \
    -e WP_DB_PASSWORD=db-pass \
    -e WP_WP_SITEURL=https://domain.com/ \
    -e WP_WP_HOME=https://domain.com/ \
    \
    -e WP_WPMS_ON=true \
    -e WP_WPMS_SMTP_HOST=mailserver.domain.com \
    -e WP_WPMS_SMTP_PORT=587 \
    -e WP_WPMS_MAIL_FROM=sender@domain.com \
    -e WP_WPMS_MAIL_FROM_FORCE=false \
    -e WP_WPMS_MAIL_FROM_NAME=sender@domain.com \
    -e WP_WPMS_MAIL_FROM_NAME_FORCE=false \
    -e WP_WPMS_SMTP_AUTH=true \
    -e WP_WPMS_SMTP_USER=smtpuser \
    -e WP_WPMS_SMTP_PASS=smtppass \
    -e WP_WPMS_SSL= \
    -e WP_WPMS_MAILER=smtp \
    \
    -e WPS3_PROVIDER=custom \
    -e WPS3_KEY=accesskey \
    -e WPS3_SECRET=secretkey \
    -e WPS3_FOLDER= \
    -e WPS3_REGION= \
    -e WPS3_BUCKET=bucketname \
    -e WPS3_URL_PREFIX=https://s3.domain.com/bucketname/ \
    -e WPS3_PATHSTYLE=true \
    -e WPS3_ENDPOINT=https://s3.domain.com \
    \
    -e WP_AUTH_KEY='INSERT-SAFE-VALUES-HERE' \
    -e WP_SECURE_AUTH_KEY='INSERT-SAFE-VALUES-HERE' \
    -e WP_LOGGED_IN_KEY='INSERT-SAFE-VALUES-HERE' \
    -e WP_NONCE_KEY='INSERT-SAFE-VALUES-HERE' \
    -e WP_AUTH_SALT='INSERT-SAFE-VALUES-HERE' \
    -e WP_SECURE_AUTH_SALT='INSERT-SAFE-VALUES-HERE' \
    -e WP_LOGGED_IN_SALT='INSERT-SAFE-VALUES-HERE' \
    -e WP_NONCE_SALT='INSERT-SAFE-VALUES-HERE' \
    \
    -v /path-to-composer.json:/var/www/composer.json \
    wordpress-docker    
```

This command configure Wordpress Database, "WP Mail SMTP" and "WP S3 Offloading".  
You can create security wordpress constants, on this url: https://roots.io/salts.html    

> *You also found a ready composer.json and docker-compose.yaml file within example folder.*

## Can I use it on Kubernetes?

I think so. I did not test this yet, but I think this can be an interesting use case:   
So: **Why not?**

## Composer Proxy / Cache

Especially in Kubernetes environments, I recommend to use a composer proxy, like [Velocita](https://github.com/isaaceindhoven/composer-velocita)

The reason for that are simple:
  - Much better deployment initialization timing (especially when used with > 1 instance of same wordpress)
  - less external traffic
  - you can configure private composer registry authorization on proxy level

## Commercial Plugins / Themes

For this I would link a website from Bedrock: https://roots.io/bedrock/docs/private-or-commercial-wordpress-plugins-as-composer-dependencies/

Also Gitlab.com provides great composer packing registry build in, which can be used.

## License

MIT