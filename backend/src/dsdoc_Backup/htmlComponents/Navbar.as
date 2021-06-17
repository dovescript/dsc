package dsc.docGenerator.htmlComponents {
    import dsc.semantics.*;
    import dsc.docGenerator.tags.*;
    import dsc.util.PathHelpers;
    import dsc.util.StringHelpers;

    public function Navbar(rootPath:String, currentNavId:String, navbarLinks:*):String {
        var primaryLeftItems:Array = [
            NavbarItem('Overview', 'overview', rootPath, currentNavId, navbarLinks),
            NavbarItem('Package', 'package', rootPath, currentNavId, navbarLinks),
            NavbarItem('Class', 'class', rootPath, currentNavId, navbarLinks),
        ];
        return StringHelpers.apply(<![CDATA[<div class="sticky-top" id="appNavbar">
    <nav class="navbar navbar-expand-sm navbar-light bg-light">
        <button class="navbar-toggler" style="float: right" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation"><span class="navbar-toggler-icon"></span></button>
        <div class="collapse navbar-collapse" id="navbarSupportedContent">
            <ul class="navbar-nav mr-auto">
                $primaryLeftItems
            </ul>
        </div>
    </nav>
    <div class="subNavbar">
        <div id="navListSearch">
            <label for="navSearch" style="margin-bottom: 0">Search:</label>
            <button id="navSearchIcon" class="form-control-search"></button>
            <input id="navSearch" class="form-control" placeholder="Search">
            <button class="form-control-reset" id="searchReset"></button>
        </div>
    </div>
</div>]]>.toString(),
            {
                primaryLeftItems: primaryLeftItems.join('\n')
            });
    }
}