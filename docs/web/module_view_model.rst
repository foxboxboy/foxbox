:github_url: hide

View Model
==========

A SubViewportContainer that keeps its SubViewport the same size as the main one, for drawing first person hands and weapons in a layer of their own.

.. warning::

    Shelved. It works, but is not being developed and nothing else in the library uses it.

:ref:`class_FoxViewModelContainer` keeps a ``SubViewport`` the same size as the main viewport when
the window is resized. Everything else, including keeping the two cameras' fields of view in sync,
is manual.

.. toctree::
   :maxdepth: 1

   class_foxviewmodelcontainer
