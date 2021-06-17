package dsc.docGenerator.htmlComponents {
    import dsc.semantics.*;
    import dsc.docGenerator.tags.*;
    import dsc.util.PathHelpers;
    import dsc.util.StringHelpers;

    public function NavbarItem(content:String, navId:String, rootPath:String, currentNavId:String, navbarLinks:*):String {
        var isCurrent:Boolean = navId == currentNavId;
        var link:String = navbarLinks[navId];
        var liInner = isCurrent || !link ?
            '<span class="nav-link">' + content +  '</span>' :
            '<a class="nav-link" href="' + PathHelpers.join(rootPath, link) + '">' + content + '</a>';
        return '<li class="nav-item"' + (isCurrent ? ' aria-current="page"' : '') + '>' + liInner + '</li>';
    }
}