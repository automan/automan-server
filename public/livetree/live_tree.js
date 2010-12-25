// LiveTree, version: 0.1.2
//
// Home page: http://www.epiphyte.ca/code/live_tree.html
//
// Copyright (c) 2005-2006 Emanuel Borsboom
// 
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the 
// "Software"), to deal in the Software without restriction, including 
// without limitation the rights to use, copy, modify, merge, publish, 
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the 
// following conditions:
// 
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

function LiveTree(id, options) {
    this.id = id;
    
    if (options == null) {
        options = {};
    }
    
    this.dataUrl = options.dataUrl;
    this.cssClass = options.cssClass;
    this.cssStyle = options.cssStyle;
    this.expandRootItem = (options.expandRootItem == null ? true : options.expandRootItem);	
    this.hideRootItem = (options.hideRootItem == null ? false : options.hideRootItem);
    this.rootItemId = options.rootItemId;
    this.expandItemOnClick = (options.expandItemOnClick == null ? true : options.expandItemOnClick);
    this.initialData = options.initialData;
    this.scroll = (options.scroll == null ? true : options.scroll);
    this.preloadItems = (options.preloadItems == null ? true : options.preloadItems);
    
    this.collapsedItemIconHtml = options.collapsedItemIconHtml;
    this.expandedItemIconHtml = options.expandedItemIconHtml;
    this.leafIconHtml = options.leafIconHtml;
    this.loadingIconHtml = options.loadingIconHtml;
    this.loadingTreeHtml = options.loadingTreeHtml;
    this.searchingHtml = options.searchingHtml;
    this.loadingItemHtml = options.loadingItemHtml;
    this.onClickCheckbox=options.onClickCheckbox;
    this.onClickRadio=options.onClickRadio||Prototype.emptyFunction;
    this.onClickItem = options.onClickItem;
    this.allowClickBranch = (options.allowClickBranch == null ? true : options.allowClickBranch);
    this.allowClickLeaf = (options.allowClickLeaf == null ? true : options.allowClickLeaf);
    this.onExpandItem = options.onExpandItem;
    this.onCollapseItem = options.onCollapseItem;
    this.onLoadItem = options.onLoadItem;
    this.radioName=options.radioName;
    this.checkboxName = options.checkboxName;
    
    this._root = {};
    this._itemsIndex = {};
    this._activeItemId = null;
    this._scrollToItemIdOnLoad = null;
    this._scrollToItemMustBeExpanded = false;
    this._searchCount = 0;
    this._preloadCount = 0;
    this._updateItemDisplay = null;
}

//LiveTree.DEV_SHOW_PRELOADS = true;
//LiveTree.DEV_SHOW_ITEM_IDS = true;

LiveTree.prototype._markItemForUpdateDisplay = function (item) {
    var tree = this;
    // This is not very intelligent yet... basically if only one item needs to be updated, that's fine, otherwise the whole tree is updated.
    if (tree._updateItemDisplay == null) {
        tree._updateItemDisplay = item;
    } else if (tree._updateItemDisplay != item) {
        tree._updateItemDisplay = tree._root;
    }	
}

LiveTree.prototype._getClass = function (suffix) {
    if (suffix != "") {
        suffix = "_" + suffix;
    }
    result = 'live_tree' + suffix;
    if (this.cssClass != null) {
        result += ' ' + this.cssClass + suffix;
    }
    return result;
}

LiveTree.prototype._escapeId = function (itemId) {
    //XXX find out exactly what characters are allowed in HTML id
    return escape(itemId);
}

LiveTree.prototype._getCollapsedItemIconHtml = function (item) {
    if (this.collapsedItemIconHtml != null) {
        return this.collapsedItemIconHtml;
    } else {
        return '<img src="/livetree/live_tree_transparent_pixel.gif" alt="&gt;" id="' + this.id + '_item_icon_' + this._escapeId(item.id) + '" class="' + this._getClass("item_icon") + ' ' + this._getClass("branch_collapsed_icon") + '" />';
    }
}

LiveTree.prototype._getExpandedItemIconHtml = function (item) {
    if (this.expandedItemIconHtml != null) {
        return this.expandedItemIconHtml;
    } else {
        return '<img src="/livetree/live_tree_transparent_pixel.gif" alt="v" id="' + this.id + '_item_icon_' + this._escapeId(item.id) + '" class="' + this._getClass("item_icon") + ' ' + this._getClass("branch_expanded_icon") + '" />';
    }
}

LiveTree.prototype._getLeafIconHtml = function (item) {
    if (this.leafIconHtml != null) {
        return this.leafIconHtml;
    } else {
        return '<img src="/livetree/live_tree_transparent_pixel.gif" alt=" " id="' + this.id + '_item_icon_' + this._escapeId(item.id) + '" class="' + this._getClass("item_icon") + ' ' + this._getClass("leaf_icon") + '" />';
    }
}

LiveTree.prototype._getLoadingIconHtml = function () {
    if (this.loadingIconHtml != null) {
        return this.loadingIconHtml;
    } else {
        return '<img src="/livetree/live_tree_loading_spinner.gif" alt="[loading]" class="' + this._getClass("loading_icon") + '" />';
    }
}

LiveTree.prototype._getLoadingTreeHtml = function () {
    if (this.loadingTreeHtml != null) {
        return this.loadingTreeHtml;
    } else {
        return '<span class="' + this._getClass("loading_tree") + '">' + this._getLoadingIconHtml() + 'Loading tree data&hellip;</span>';
    }
}

LiveTree.prototype._getSearchingHtml = function () {
    if (this.searchingHtml != null) {
        return this.searchingHtml;
    } else {
        return '<div class="' + this._getClass("searching") + '">' + this._getLoadingIconHtml() + 'Searching for item&hellip;</div>';
    }
}

LiveTree.prototype._getLoadingItemHtml = function () {
    if (this.loadingItemHtml != null) {
        return this.loadingItemHtml;
    } else {
        return this._getLoadingIconHtml() + 'Loading&hellip;';
    }
}

LiveTree.prototype._startPreloads = function (item) {
    var tree = this;
    if (!tree.preloadItems || tree._preloadCount > 0) {
        return false;
    }
    if (item == null) {
        item = tree._root;
    }
    //alert("XXX startPreloads " + item.id);
    if (!item.isExpanded || item.isLoading) {
        return false;
    }
    var tailBranch = true;
    for (var i = 0; i < item.children.length; i++) {
        var child = item.children[i];
        if (!child.isLeaf && ( child.isLoaded || child.isLoading )) {
            tailBranch = false;
        }
    }
    var doLoad = false;
    if (tailBranch) {
        for (var i = 0; i < item.children.length; i++) {
            var child = item.children[i];
            if (!child.isLeaf) {
                if (!child.isLoaded && !child.isLoading) {
                    //alert("setting loading for " + child.id);
                    doLoad = true;
                    child.isLoading = true;
                    child.isLoadingBackground = true;
                }
            }
        }
    }
    var didLoad = false;
    if (doLoad) {
        //alert("XXX preloading children of " + item.id);
        tree._preloadCount++;
        if (item == tree._root) {
            tree._requestItem(tree._root.children[0].id, 2, tree._onPreloadItemReceived.bind(tree));	
        } else {
            tree._requestItem(item.id, 3, tree._onPreloadItemReceived.bind(tree));	
        }
        if (LiveTree.DEV_SHOW_PRELOADS) {
            tree._markItemForUpdateDisplay(item);
        }
        didLoad = true;
    } else {
        for (var i = 0; i < item.children.length; i++) {
            var child = item.children[i];
            if (!child.isLeaf && child.isLoaded) {
                if (tree._startPreloads(child)) {
                    didLoad = true;
                }
            }
        }
    }

    return didLoad;
}

LiveTree.prototype._stopLoading = function () {
    var tree = this;
    function recurse(item) {
        if (item.isLoading) {
            item.isLoading = false;
            item.isExpanded = false;
        }		
        if (item.children != null) {
            for (var i = 0; i < item.children.length; i++) {
                recurse(item.children[i]);
            }
        }
    }
    recurse(tree._root);
    tree._markItemForUpdateDisplay(tree._root);
    tree._searchCount = 0;
    tree._preloadCount = 0;
    tree._updateDisplay();
}

LiveTree.prototype._onItemFailure = function (request) {
    alert("LiveTree error: could not get data from server: HTTP error: " + request.status);
    //alert(request.responseText); //XXX
    this._stopLoading();
}

LiveTree.prototype._requestItem = function (itemId, depth, onItemCallback, options) {
    var tree = this;	
    if (options == null) {
        options = {};
    }
    var url = tree.dataUrl;
    var requestOptions = new Object();
    var delim = "?";
    if (itemId != null) {
        requestOptions.itemId = itemId;
        url += delim + "item_id=" + escape(itemId);		
        delim = "&";
    }
    if (depth != null) {
        requestOptions.depth = depth;
        url += delim + "depth=" + depth;
        delim = "&";
    }
    if (options.includeParents) {
        requestOptions.includeParents = true;
        requestOptions.rootItemId = tree.rootItemId;
        url += delim + "include_parents=1&root_item_id=" + escape(tree.rootItemId);
        tree._searchCount++;
    }
    if (options.initialRequest) {
        requestOptions.initialRequest = true;
    }
    new Ajax.Request(url, {onSuccess: function (request) { tree._onItemResponse(request, onItemCallback, requestOptions) }, onFailure: tree._onItemFailure.bind(tree), evalScripts:true, asynchronous:true, method:"get"});
    return true;
}

LiveTree.prototype._onExpandItemReceived = function (item, requestOptions) {
    var tree = this;
    //alert("XXX _onExpandItemReceived item.id=" + item.id);
    item.isLoading = false;
    tree._markItemForUpdateDisplay(item);
    tree._startPreloads();
    tree._updateDisplay();	
}

LiveTree.prototype._onPreloadItemReceived = function (item, requestOptions) {
    var tree = this;
    if (tree._preloadCount <= 0) {
        return;
    }
    //alert("XXX got preload item");
    tree._preloadCount--;
    item.isLoading = false;
    for (var i = 0; i < item.children.length; i++) {
        item.children[i].isLoading = false;		
    }
    tree._startPreloads();
    tree._markItemForUpdateDisplay(item);
    tree._updateDisplay();	
}

LiveTree.prototype._onClickExpand = function (item) {
    var tree = this;
    var expanded = tree._expandItem(item);
    tree._updateDisplay();	
    if (expanded) {
        tree.scrollToItem(item.id);
        if (item.isLoading) {
            tree._scrollToItemIdOnLoad = item.id;
            tree._scrollToItemMustBeExpanded = true;
        }
        if (tree.onExpandItem != null) {
            tree.onExpandItem(item);
        }
    }
}

LiveTree.prototype._onClickCollapse = function (item) {
    var tree = this;
    if (!item.isExpanded) {
        return;
    }
    item.isExpanded = false;
    tree._markItemForUpdateDisplay(item);
    tree._updateDisplay();	
    if (tree.onCollapseItem != null) {
        tree.onCollapseItem(item);
    }
}
LiveTree.prototype._onClickCheckbox = function (item) {
    var tree = this;
    if (tree.onClickCheckbox){
        tree.onClickCheckbox(item,tree._checkboxId(item));
    }
}
LiveTree.prototype._onClickItem = function (item) {
    var tree = this;
    if (tree.expandItemOnClick && !item.isExpanded && !item.isLeaf) {
        tree._onClickExpand(item);		
    }
    if (tree.onClickItem != null && ((tree.allowClickLeaf && item.isLeaf) || (tree.allowClickBranch && !item.isLeaf))) {
        tree.onClickItem(item);
    }
    tree._updateDisplay();
}

LiveTree.prototype._getItem = function (itemId) {
    return this._itemsIndex[itemId];
}

LiveTree.prototype._getItemElementId = function (itemId) {
    return this.id + "_item_" + this._escapeId(itemId);
}

LiveTree.prototype._getItemElement = function (itemId) {
    return $(this._getItemElementId(itemId));
}

LiveTree.prototype._isRootItem = function (item) {
    var tree = this;
    return item == tree._root || (tree.hideRootItem && item == tree._root.children[0]);
}

LiveTree.prototype._renderItemHeading = function (item) {
    var tree = this;
    var html = '';
    if (!item.isLeaf) {
        html += '<a href="#" id="' + tree.id + '_branch_expand_collapse_link_' + tree._escapeId(item.id) + '" class="' + this._getClass("branch_expand_collapse_link") + '">';
        if (item.isExpanded) {
            html += tree._getExpandedItemIconHtml(item);
        } else {
            html += tree._getCollapsedItemIconHtml(item);
        }
        html += '</a>';
    } else {
        html += tree._getLeafIconHtml(item);
    }
    var itemLinkExists = false;
    var extraNameClass = "";
    if (item.id == tree._activeItemId) {
        extraNameClass = " " + this._getClass("active_item_name");
    }
		
		var cssClass = this._getClass("item_name");
  	var name_html = '';
		
		if (item.cssClass){
			name_html += "<s class='icon "+item.cssClass+"'></s>";
		}

    name_html += '<span id="' + tree.id + '_item_name_' + tree._escapeId(item.id) + '" class="' + this._getClass("item_name") + extraNameClass + '">' + item.name + '</span>';
    if (((tree.onClickItem != null && ((tree.allowClickLeaf && item.isLeaf) || (tree.allowClickBranch && !item.isLeaf))) ||
            (tree.expandItemOnClick && !item.isLeaf && !item.isExpanded)) && !item.isLoadingDisplay) {
        name_html = '<a href="#" id="' + tree.id + '_item_link_' + tree._escapeId(item.id) + '" class="' + this._getClass("item_link") + '">' + name_html + '</a>';
        itemLinkExists = true;
    }
    if (LiveTree.DEV_SHOW_ITEM_IDS) {
        name_html = "(" + item.id + ") " + name_html;
    }
		if (this.checkboxName && !item.nocheckbox){
			parent_id=0
			if(item.parent){parent_id=item.parent.id}
			name_html='<input onclick=onClickCheckbox(this) type="checkbox" name="'+this.checkboxName+'" id=item_'+item.id+' class=item_class_'+parent_id+' value='+item.id+'>&nbsp;&nbsp;'+name_html
		}else{
			if(this.radioName){
			 parent_id=0
			 if(item.parent){parent_id=item.parent.id}
			 name_html='<input type="radio" name="'+this.radioName+'" id=item_'+item.id+' class=item_class_'+parent_id+' value='+item.id+'>&nbsp;&nbsp;'+name_html
		 }
		}
    html += name_html;
    if (LiveTree.DEV_SHOW_PRELOADS) {
        if (item.isLoading && item.isLoadingBackground) {
            html += " " + tree._getLoadingIconHtml();
        }
    }
    $(tree.id + "_item_heading_" + tree._escapeId(item.id)).innerHTML = html;
    if (!item.isLeaf) {
        if (item.isExpanded) {
            $(tree.id + '_branch_expand_collapse_link_' + tree._escapeId(item.id)).onclick = function () { tree._onClickCollapse(item); return false }		
        } else {
            $(tree.id + '_branch_expand_collapse_link_' + tree._escapeId(item.id)).onclick = function () { tree._onClickExpand(item); return false }
        }
    }
    if (itemLinkExists) {
        $(tree.id + '_item_link_' + tree._escapeId(item.id)).onclick = function() { tree._onClickItem(item); return false }
    }
}
LiveTree.prototype._hideItem = function (child) {
    var tree = this;
    var elem = tree._getItemElement(child.id);
    if (elem) {
        $(tree.id).removeChild(elem);
        if (child.isLoaded || (child.isLoading && !child.isLoadingBackground)) {
            tree._hideItemChildren(child);
        }
    }
}

LiveTree.prototype._hideItemChildren = function (item) {
    var tree = this;
    tree._hideItem(tree._getLoadingDisplayChild(item));
    if (!item.isLoading) {
        for (var i = 0; i < item.children.length; i++) {
            tree._hideItem(item.children[i]);
        }
    }
    item.childrenVisible = false;
}

LiveTree.prototype._updateItemChildren = function (item, afterElem, indentLevel, containerElem) {
    var tree = this;
    
    function doUpdateChild(child) {
        var elem = tree._getItemElement(child.id);
        if (elem == null) {
            var html = "";
            html += '<div id="' + tree.id + '_item_' + tree._escapeId(child.id) + '" class="' + tree._getClass("item") + '">';
            for (var j = 0; j < indentLevel; j++) {
                html += '<div class="' + tree._getClass("item_indent") + '">';
            }
            html += '<span id="' + tree.id + '_item_heading_' + tree._escapeId(child.id) + '" class="' + tree._getClass("item_heading") + '"></span>';
            for (var j = 0; j < indentLevel; j++) {
                html += '</div>';
            }
            html += '</div>';
            new Insertion.After(afterElem, html);
            elem = tree._getItemElement(child.id);
        }
				tree._renderItemHeading(child);
				afterElem = elem;
        if (child.isLoaded || (child.isLoading && !child.isLoadingBackground)) {
            afterElem = tree._updateItemChildren(child, afterElem, indentLevel + 1, containerElem);
        }
    }
    
    if (!item.isExpanded) {
        tree._hideItemChildren(item);
    } else {
        if (item.isLoaded) {
            tree._hideItem(tree._getLoadingDisplayChild(item));
            for (var i = 0; i < item.children.length; i++) {	
                doUpdateChild(item.children[i]);
            }
        } else {
            doUpdateChild(tree._getLoadingDisplayChild(item));
        }
        item.childrenVisible = true;
    }
    return afterElem;
}

LiveTree.prototype._getLoadingDisplayChild = function (item) {
    var tree = this;
    var loadingChild = {id: "___LIVE_TREE_LOADING_" + item.id + "___", 
                         name: tree._getLoadingItemHtml(), 
                         children: [], 
                         isLoadingDisplay: true};
    tree._setItemDerivedAttributes(loadingChild);
    return loadingChild;
}

LiveTree.prototype._updateDisplay = function () {
    var tree = this;
    if (tree._searchCount > 0) {
        Element.show(tree.id + "_searching");
    } else {
        Element.hide(tree.id + "_searching");
    }
    var updateItem = tree._updateItemDisplay;	
    if (updateItem != null) {
        tree._updateItemDisplay = null;
        if (tree._isRootItem(updateItem)) {
            if (tree.hideRootItem) {
                updateItem = tree._root.children[0];
            }
            tree._updateItemChildren(updateItem, $(tree.id + "_root"), 0, $(tree.id));
        } else {
            tree._renderItemHeading(updateItem);
            
            var indentLevel = 0;
            var parentItem = updateItem;
            while (!tree._isRootItem(parentItem)) {
                indentLevel++;
                parentItem = parentItem.parent;
            }
            
            if (updateItem.isLoaded || (updateItem.isLoading && !updateItem.isLoadingBackground)) {
                tree._updateItemChildren(updateItem, tree._getItemElement(updateItem.id), indentLevel, $(tree.id));
            }
        }
    }
    tree._checkScrollOnLoad();
}

LiveTree.prototype._checkScrollOnLoad = function () {
    var tree = this;
    if (tree._scrollToItemIdOnLoad == null) {
        return;
    }
    var item = tree._itemsIndex[tree._scrollToItemIdOnLoad];
    if (item == null) {
        return;
    }
    if (tree._scrollToItemMustBeExpanded) {
        if (item.isLoaded) {
            // The user may have collapsed the item while it was loading, so only scroll to it if it's still expanded.
            if (item.isExpanded) {
                tree.scrollToItem(item.id);
            }
            tree._scrollToItemIdOnLoad = null;
        }
    } else {
        tree.scrollToItem(item.id);
        tree._scrollToItemIdOnLoad = null;		
    }
}

LiveTree.prototype._getElementPosition = function (destinationLink) {
    // borrowed from http://www.sitepoint.com/print/scroll-smoothly-javascript
    var destx = destinationLink.offsetLeft;  
    var desty = destinationLink.offsetTop;
    var thisNode = destinationLink;
    while (thisNode.offsetParent &&  
            (thisNode.offsetParent != document.body)) {
        thisNode = thisNode.offsetParent;
        destx += thisNode.offsetLeft;
        desty += thisNode.offsetTop;
    }
    return { x: destx, y: desty }
}

LiveTree.prototype._scrollTo = function (top) {
    var tree = this;
    if (!tree.scroll) {
        return;
    }
    var containerElem = $(tree.id);
    containerElem.scrollTop = top;
}

LiveTree.prototype.scrollToItem = function (itemId) {
    var tree = this;
    if (!tree.scroll) {
        return;
    }
    var itemElem = tree._getItemElement(itemId);
    if (itemElem == null) {
        return;
    }
    var containerElem = $(tree.id);
    var itemPos = tree._getElementPosition(itemElem);
    var containerPos = tree._getElementPosition(containerElem);
    var itemTop = itemPos.y - containerPos.y;
    var containerHeight = containerElem.offsetHeight - 35; //HACK: adjust for space used by scrollbars and other decoration
    if (itemTop + itemElem.offsetHeight > containerElem.scrollTop + containerHeight ||
            itemTop < containerElem.scrollTop) {
        // item is currently not entirely visible
        if (itemElem.offsetHeight > containerHeight) {
            // item is too big to fit, so scroll to the top
            tree._scrollTo(itemTop);
        } else {
            if (itemTop < containerElem.scrollTop + containerHeight) {
                // item is partially onscreen (the top is showing), so put whole item at bottom
                tree._scrollTo(itemTop + itemElem.offsetHeight - containerHeight);
            } else {
                // item is entirely offscreen, so center it
                tree._scrollTo(itemTop - containerHeight/2 + itemElem.offsetHeight/2);
            }
        }
    }
    tree._scrollToItemOnLoad = null;
}

LiveTree.prototype._expandItem = function (item) {
    var tree = this;
    if($('item_'+item.id)&&$('item_'+item.id).disabled){
    	return false
    }
    
    // Make sure all item's parents are expanded as well
    var didExpand = false;
    var parent = item.parent;
    while (parent != tree._root && parent != null) {
        if (!parent.isExpanded) {
            parent.isExpanded = true;
            tree._markItemForUpdateDisplay(parent);
            didExpand = true;
        }
        parent = parent.parent;
    }	

    // Expand the selected item
    var needToLoad = false;
    if (!item.isExpanded) {
        needToLoad = (item.children == null && !item.isLoading);
        if (needToLoad) {
            item.isLoading = true;
        }
        item.isLoadingBackground = false;
        item.isExpanded = true;
        tree._markItemForUpdateDisplay(item);
        didExpand = true;
    }
    
    // If the item has not loaded, load it now
    if (needToLoad) {
        tree._requestItem(item.id, 2, tree._onExpandItemReceived.bind(tree));	
    }	

    tree._startPreloads();	
    return didExpand;
}

LiveTree.prototype._onExpandItemParentsReceived = function (item, requestOptions) {
    var tree = this;
    var requestedItem = tree._getItem(requestOptions.itemId);
    this._expandItem(requestedItem);
    tree._startPreloads();
    tree._updateDisplay();	
}

LiveTree.prototype.expandItem = function (itemId) {
    var tree = this;
    var item = tree._getItem(itemId);
    var search = false;
    if (item == null) {
        tree._requestItem(itemId, 2, tree._onExpandItemParentsReceived.bind(tree), { includeParents: true });
        search = true;
    } else {
        this._expandItem(this._itemsIndex[itemId]);
    }
    tree._updateDisplay();
    if (search) {
        tree._scrollTo(0);
        tree._scrollToItemIdOnLoad = itemId;		
        tree._scrollToItemMustBeExpanded = false;
    } else {
        tree.scrollToItem(itemId);
    }
}

LiveTree.prototype._onExpandParentsOfItemReceived = function (item, requestOptions) {
    var tree = this;
    //alert("XXX _onExpandParentsOfItemReceived item.id=" + item.id);
    var requestedItem = tree._getItem(requestOptions.itemId);
    tree._expandItem(requestedItem.parent);
    tree._startPreloads();
    tree._updateDisplay();	
}

LiveTree.prototype.expandParentsOfItem = function (itemId) {
    var tree = this;
    var item = tree._getItem(itemId);
    var search = false;
    if (item == null) {
        tree._requestItem(itemId, 1, tree._onExpandParentsOfItemReceived.bind(tree), { includeParents: true });
        search = true;
    } else {
        tree._expandItem(item.parent);
    }
    tree._updateDisplay();
    if (search) {
        tree._scrollTo(0);
        tree._scrollToItemIdOnLoad = itemId;		
        tree._scrollToItemMustBeExpanded = false;
    } else {
        tree.scrollToItem(itemId);
    }
}

LiveTree.prototype.activateItem = function (itemId) {
    var tree = this;
    // un-highlight the old active item
    var oldElem = $(tree.id + '_item_name_' + tree._escapeId(tree._activeItemId));
    if (oldElem != null) {
        oldElem.className = tree._getClass("item_name");
    }
    // highlight the new active item
    var elem = $(tree.id + '_item_name_' + tree._escapeId(itemId));
    if (elem != null) {
        elem.className = tree._getClass("item_name") + " " + tree._getClass("active_item_name");
    }
    tree._activeItemId = itemId;
    tree.scrollToItem(itemId);
}

LiveTree.prototype.getHtml = function() {
    var tree = this;	
    var html = '';
    html += '<div id="' + tree.id + '" class="' + tree._getClass("") + '"';
    if (tree.cssStyle != null) {
        html += ' style="' + tree.cssStyle + '"';
    }
    html += '>';
    html += '<div id="' + tree.id + '_searching" style="display:none">' + tree._getSearchingHtml() + '</div>';
    html += '<div id="' + tree.id + '_loading">' + tree._getLoadingTreeHtml() + '</div>';
    html += '<div id="' + tree.id + '_root"></div>';
    html += '</div>';
    return html;
}

LiveTree.prototype._setItemDerivedAttributes = function (child) {
    child.isLeaf = !(child.children == null || child.children.length > 0);
    child.isLoaded = child.children != null;
}

LiveTree.prototype._setupNewItemChildren = function (item) {
    var tree = this;
    if (item.children != null) {
        for (var i = 0; i < item.children.length; i++) {
            var child = item.children[i];
            tree._setItemDerivedAttributes(child);
            child.parent = item;
            tree._itemsIndex[child.id] = child;
            tree._setupNewItemChildren(child);
        }
    }
}

LiveTree.prototype._addNewItems = function (newItem) {
    var tree = this;
    var oldItem = tree._getItem(newItem.id);
    if (newItem.children != null && oldItem != null) {
        if (!oldItem.isLoaded) {		
            // Old item has been seen, but its children were not loaded.
            // New item does have children, so add the children to the old item and flag it as as loaded.
            oldItem.children = newItem.children;
            tree._setupNewItemChildren(oldItem);
            oldItem.isLoaded = true;
        } else {
            // Item is already in the tree and has loaded, so recurse to new item's children
            for (var i = 0; i < newItem.children.length; i++) {
                tree._addNewItems(newItem.children[i]);
            }
        }
    }
    return oldItem;
}

LiveTree.prototype._onItemResponse = function (request, onItemCallback, requestOptions) {
    var tree = this;
    if (requestOptions.includeParents && tree._searchCount > 0) {
        tree._searchCount--;
    }
    var item;
    try {
        eval("item = " + request.responseText);
    } catch (e) {
        alert("LiveTree error: cannot parse data from server: " + e);
        tree._stopLoading();
        return;
    }
    
    if (requestOptions.initialRequest) {
        tree._handleInitialItem(item);
    } else {	
        var oldItem = tree._addNewItems(item);
        if (oldItem == null) {
            alert("LiveTree error: cannot add received item to tree");
            tree._stopLoading();
            return;
        }
    }
    onItemCallback(oldItem, requestOptions);
}

LiveTree.prototype._onInitialItemReceived = function () {
    var tree = this;
    this.rootItemId = tree._root.children[0].id;
    Element.hide($(tree.id + "_loading"));
    if (tree.hideRootItem || tree.expandRootItem) {
        tree._expandItem(tree._root.children[0]);
    }
    tree._root.isExpanded = true;
    tree._markItemForUpdateDisplay(tree._root);
    tree._startPreloads();
    tree._updateDisplay();		
}

LiveTree.prototype._handleInitialItem = function (item) {
    var tree = this;
    tree._root.children = [item];
    tree._root.isLoaded = true;
    tree._setupNewItemChildren(tree._root);
}

LiveTree.prototype.start = function() {
    var tree = this;	
    if (tree.initialData != null) {
        tree._handleInitialItem(tree.initialData);
        tree._onInitialItemReceived(tree.initialData);
    } else {
        tree._requestItem(tree.rootItemId, (tree.expandRootItem || tree.hideRootItem) ? 2 : 1, tree._onInitialItemReceived.bind(tree), { initialRequest: true });
    }
}

LiveTree.prototype.render = function () {
    var tree = this;	
    document.write(tree.getHtml());
    tree.start();
}
