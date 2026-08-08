.. warning::

   Shelved. It works, but it is not being developed, and nothing else in the library uses it.
   Expect it to change or move to ``deprecated``.

The standard trick for first person view models: render held items through a separate camera
into a ``SubViewport`` composited over the world, so a long weapon never clips into a wall you
are standing against.

:ref:`class_FoxViewModelContainer` handles the one piece of bookkeeping that is easy to forget,
which is keeping the sub viewport the same size as the main one when the window resizes.

Everything else is on you. Put a camera and the view model inside the ``SubViewport`` child, and
keep that camera's field of view in sync with the world camera yourself. Nothing here does that
for you, which is a large part of why the module is shelved rather than finished.
