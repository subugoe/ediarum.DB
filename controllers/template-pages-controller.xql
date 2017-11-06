xquery version "3.0";

module namespace template-pages="http://www.bbaw.de/telota/software/ediarum-app/template-pages";
import module namespace config="http://www.bbaw.de/telota/software/ediarum/config";
import module namespace ediarum="http://www.bbaw.de/telota/software/ediarum/ediarum-app";

(:~
 : Fürs Login.
 :)
declare function template-pages:login-menu($node as node(), $model as map(*)) as node() {
    let $log-action := request:get-parameter('laction','')
    let $session := config:manage-session($log-action)
    return
        config:trash($session),
    if (xmldb:get-current-user() eq 'guest')
    then
    <li class="dropdown">
        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">Login<span class="caret"/></a>
        <ul class="dropdown-menu">
            <form action="" method="post" class="navbar-form navbar-left">
            <input type="hidden" name="laction" value="login"/>
            <li>
                <label for="lname" class="sr-only">Name:</label><input type="text" class="form-control" placeholder="Name" name="user"/>
            </li>
                <li>
                <li role="separator" class="divider"/>
                <label for="lpass" class="sr-only">Passwort:</label>
                <input type="password" class="form-control" placeholder="Passwort" name="pass"/>
                </li>
                <li role="separator" class="divider"/>
                <li> <input type="submit" class="btn btn-default" value="Einloggen"/> </li>
            </form>
        </ul>
    </li>
    else
    <li class="dropdown">
        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">Logged in as {xmldb:get-current-user()}<span class="caret"/></a>
        <ul class="dropdown-menu">
            <form action="" method="post" class="navbar-form navbar-left">
            <li>
                <input type="hidden" name="laction" value="logout"/>
                <input type="hidden" name="user" value="guest"/>
                <input type="hidden" name="pass" value="guest"/>
                <input type="submit" class="btn btn-default" value="Logout"/>
            </li>
            </form>
        </ul>
    </li>
};

(:
 :~ Interne Bereiche
 :)
 declare function template-pages:admin-menus($node as node(), $model as map(*)) as node()* {
    (:if (xmldb:get-current-user() eq 'guest'):)
    if (exists(index-of(xmldb:get-user-groups(xmldb:get-current-user()),'dba')) )
    then
     (<li class="dropdown">
        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">Verwaltung<span class="caret"/></a>
        <ul class="dropdown-menu">
            <li>
                <a href="{ediarum:get-ediarum-dir(request:get-context-path())}/projects.html">Projekte</a>
            </li>
            <li>
                <a href="{ediarum:get-ediarum-dir(request:get-context-path())}/existdb.html">exist-db</a>
            </li>
            <li>
                <a href="{ediarum:get-ediarum-dir(request:get-context-path())}/scheduler.html">Scheduler</a>
            </li>
            <li>
                <a href="{ediarum:get-ediarum-dir(request:get-context-path())}/setup.html">Setup</a>
            </li>
        </ul>
    </li> (:),
    <li class="dropdown">
        <a href="#" class="dropdown-toggle" data-toggle="dropdown">Schemata</a>
        <ul class="dropdown-menu">
            {config:zeige-schemata()}
        </ul>
    </li>:) )
    else if (exists(index-of(xmldb:get-user-groups(xmldb:get-current-user()),'nutzer')) )
    then
     (<li class="dropdown">
        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">Projekte<span class="caret"/></a>
        <ul class="dropdown-menu">
            {for $project in config:get-projects()
            return
                <li><a href="{ediarum:get-ediarum-dir(request:get-context-path())}/data.html?root=/db/projects/{$project}/data">{$project}</a></li>
            }
        </ul>
    </li>,
    <li class="dropdown">
        <a href="#" class="dropdown-toggle" data-toggle="dropdown">Schemata</a>
        <ul class="dropdown-menu">
            {config:zeige-schemata()}
        </ul>
    </li>)
    else
        ()
 };

(: Projektmenüs :)
declare function template-pages:project-menu($node as node(), $model as map(*)) as node()* {
    if (config:get-current-project()
        and (exists(index-of(xmldb:get-user-groups(xmldb:get-current-user()),'dba'))
        or exists(index-of(xmldb:get-user-groups(xmldb:get-current-user()),config:project-user-group(config:get-current-project())))
        )) then (
        <li>
            <a href="{ediarum:get-ediarum-dir(request:get-context-path())}/projects/{config:get-current-project()}/data.html">{config:get-current-project()}</a>
        </li>,
        (:)<li>
            <a href="/exist/rest/db/projects/{config:get-current-project()}/web/index.xql" target="_blank">Web</a>
        </li>,:)
        let $indexes := config:get-indexes(config:get-current-project())//index
        return
            <li class="dropdown{if (exists($indexes)) then () else (" disabled")}">
                <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button"
                aria-haspopup="true" aria-expanded="false">Register<span class="caret"/></a>
                <ul class="dropdown-menu">
                    {
                        for $index in $indexes
                        let $label := $index/label/string()
                        let $id := $index/@id/string()
                        return
                            <li>
                                <a href="{ediarum:get-ediarum-dir(request:get-context-path())}/projects/{config:get-current-project()}/indexes/{$id}/items.html">{$label}</a>
                            </li>
                    }
                </ul>
            </li>
        )
    else ()
};

(: Projektadminmenüs :)
declare function template-pages:project-admin-menu($node as node(), $model as map(*)) as node()? {
    if (config:get-current-project()
        and (exists(index-of(xmldb:get-user-groups(xmldb:get-current-user()),'dba'))
        (: TODO: Umstellung auf security-manager von xmldb
        or exists(index-of(sm:get-group-managers(config:project-user-group(config:get-current-project())), xmldb:get-current-user()))
        :)
        )) then (
        <li class="dropdown">
            <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button"
            aria-haspopup="true" aria-expanded="false">Projektkonfiguration<span class="caret"/></a>
            <ul class="dropdown-menu">
                <li><a href="{ediarum:get-ediarum-dir(request:get-context-path())}/projects/{config:get-current-project()}/user.html">Benutzer</a></li>
                <li><a href="{ediarum:get-ediarum-dir(request:get-context-path())}/projects/{config:get-current-project()}/synchronisation.html">Synchronisation</a></li>
                <li><a href="{ediarum:get-ediarum-dir(request:get-context-path())}/projects/{config:get-current-project()}/scheduler.html">Scheduler</a></li>
                <li><a href="{ediarum:get-ediarum-dir(request:get-context-path())}/projects/{config:get-current-project()}/zotero.html">Zotero</a></li>
                <li><a href="{ediarum:get-ediarum-dir(request:get-context-path())}/projects/{config:get-current-project()}/indexes.html">Register</a></li>
                <!--li role="separator" class="divider"/>
                <li><a href="data.html?root=/db/projects/{config:get-current-project()}/data">Daten</a></li>
                <li><a href="data.html?root=/db/projects/{config:get-current-project()}/data-copy">Data-Copy</a></li-->
            </ul>
        </li>
        )
    else ()
};

declare function template-pages:timestamp($node as node(), $model as map(*)) as node()? {
    <span class="hidden">{current-dateTime()}</span>
};
