# NoCDN
Nocdn is an alternative to old-school CDNs

For the developers who wants to protect the privacy of the users, just put "nocdn.domain.tld/" between "https://" and the CDN.
Per example, if you want to have a javascript file on ajax.googleapis.com, and you installed NoCDN on nocdn.nsa.ovh, the URL should be like this: https://nocdn.nsa.ovh/ajax.googleapis.com/some/random/ressource.

For a user, you can bind thoses old-school CDN to your instance.
You can do it by editing the entries in your local resolver or editing your host file.

So each time you call for a cdn, the request will be handled by your instance, a big plus for privacy.

For now, we only support Javascript CDN, we will do css CDN in the future.

## CDNs supported

- ajax.aspnetcdn.com
- ajax.googleapis.com
- ajax.microsoft.com
- cdn.jsdelivr.net

- cdnjs.cloudflare.com
- code.jquery.com
- lib.sinaapp.com
- libs.baidu.com
- yandex.st
- yastatic.net

## Installation
Just download the script, check it and execute it:
```sh
wget https://raw.githubusercontent.com/nsaovh/nocdn/master/install.sh -O /tmp/install.sh
less /tmp/install.sh
bash /tmp/install.sh
```

## License :

This project is under the MIT license, if you have any question, please contact a member of the team.

## ToDo List :

- Auto install script (in progress)
- A Wiki (one day)
