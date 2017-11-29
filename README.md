# FuckCDN
Fuckcdn is an alternative to old-school CDNs

For the developpers who wants to protect the privacy of the users, just put "fuckcdn.domain.tld/" between "https://" and the CDN.
For ajax.googleapis.com and fuckcdn.nsa.ovh : https://fuckcdn.nsa.ovh/ajax.googleapis.com/some/random/ressource

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

## License :

This project is under the MIT license, if you have any question, please contact a member of the team.

## ToDo List :

- Auto install script (in progress)
- A Wiki (one day)
