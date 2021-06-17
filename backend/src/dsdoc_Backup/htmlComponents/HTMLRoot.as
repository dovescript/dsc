package dsc.docGenerator.htmlComponents {
    import dsc.semantics.*;
    import dsc.docGenerator.tags.*;
    import dsc.util.PathHelpers;
    import dsc.util.StringHelpers;

    public function HTMLRoot(headOverride:String, bodyOverride:String, content:String, rootPath:String, currentNavId:String, navbarLinks:*):String {
        navbarLinks.overview = 'index.html';
        var cssLinks:String = [
            '<link rel="stylesheet" type="text/css" href="' + PathHelpers.join(rootPath, 'bootstrap.min.css') + '">',
            '<link rel="stylesheet" type="text/css" href="' + PathHelpers.join(rootPath, 'style.css') + '">',
        ].join('\n');

        var scripts:String = [
            '<script type="text/javascript" src="' + PathHelpers.join(rootPath, 'jquery-3.5.1.slim.min.js') + '"></script>',
            '<script type="text/javascript" src="' + PathHelpers.join(rootPath, 'popper.min.js"') + '"></script>',
            '<script type="text/javascript" src="' + PathHelpers.join(rootPath, 'bootstrap.min.js') + '"></script>',
            '<script type="text/javascript" src="' + PathHelpers.join(rootPath, 'script.js') + '"></script>',
        ].join('\n');

        return StringHelpers.apply(<![CDATA[<!DOCTYPE html>
<html class="JavaDocTheme">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1.0">
    $cssLinks
    $headOverride
</head>
<body>
    $navbar
    $bodyOverride
    <div class="container" id="content">
        <div class="row justify-content-center">
            <div class="col-md-12">
                $content
            </div>
        </div>
    </div>
    $scripts
</body>
</html>]]>.toString(),
            {
                navbar: Navbar(rootPath, currentNavId, navbarLinks),
                cssLinks: cssLinks,
                headOverride: headOverride,
                bodyOverride: bodyOverride,
                content: content,
                scripts: scripts
            });
    }
}