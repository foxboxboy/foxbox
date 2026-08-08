/**
 * Togglable sidebar sections.
 *
 * custom.css styles a toctree caption as clickable and hides the list that follows it until
 * that list gets the "active" class. Nothing in Sphinx or the Read the Docs theme adds that
 * class, so without this file every section stays shut and the captions look dead.
 */

document.addEventListener("DOMContentLoaded", function () {
    var captions = document.querySelectorAll(".wy-menu-vertical p.caption");

    captions.forEach(function (caption) {
        var list = caption.nextElementSibling;
        if (!list || list.tagName !== "UL") {
            return;
        }

        // Open whichever section holds the page being viewed, so you never land somewhere with
        // the surrounding navigation collapsed.
        if (list.querySelector("li.current")) {
            caption.classList.add("active");
            list.classList.add("active");
        }

        caption.addEventListener("click", function () {
            var opening = !caption.classList.contains("active");
            caption.classList.toggle("active", opening);
            list.classList.toggle("active", opening);
        });
    });
});
