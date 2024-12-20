___

# e20-3yp-Smart Canteen Management System
___

Smart Canteen management system is a system designed to increase the efficiency of the currently existing cafeterias.

Key features:

### Enable GitHub Pages

You can put the things to be shown in GitHub pages into the _docs/_ folder. Both html and md file formats are supported. You need to go to settings and enable GitHub pages and select _main_ branch and _docs_ folder from the dropdowns, as shown in the below image.

![image](https://user-images.githubusercontent.com/11540782/98789936-028d3600-2429-11eb-84be-aaba665fdc75.png)

### Special Configurations

These projects will be automatically added into [https://projects.ce.pdn.ac.lk](). If you like to show more details about your project on this site, you can fill the parameters in the file, _/docs/index.json_

```
{
    "title": "This is the title of the project",
    "team": [
        {
            "name": "Dissanayake P.D.",
            "email": "e20084@eng.pdn.ac.lk",
            "eNumber": "E/20/084"
        },
        {
            "name": "Gunasinha H.P.M.S.",
            "email": "e20121@eng.pdn.ac.lk",
            "eNumber": "E/20/121"
        },
        {
            "name": "Munasinghe S.L.",
            "email": "e20259@eng.pdn.ac.lk",
            "eNumber": "E/20/259"
        },
        {
            "name": "Shyamantha R.M.M.",
            "email": "e20376@eng.pdn.ac.lk",
            "eNumber": "E/20/376"
        }
    ],
    "supervisors": [
        {
            "name": "Dr. Isuru Nawinne",
            "email": "isurunawinne@eng.pdn.ac.lk"
        }
    ],
    "tags": [
        "Web",
        "Embedded Systems",
        "Network Security"
    ]
}
```

Once you filled this _index.json_ file, please verify the syntax is correct. (You can use [this](https://jsonlint.com/) tool).

### Page Theme

A custom theme integrated with this GitHub Page, which is based on [github.com/cepdnaclk/eYY-project-theme](https://github.com/cepdnaclk/eYY-project-theme). If you like to remove this default theme, you can remove the file, _docs/\_config.yml_ and use HTML based website.
