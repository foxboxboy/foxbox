.. warning::

    Shelved. It works, but it is not being developed and nothing else in the library uses it. It
    may change or move to ``deprecated``.

Renders first person view models through a separate camera into a ``SubViewport`` composited
over the world, so held items do not clip into nearby geometry.

:ref:`class_FoxViewModelContainer` keeps the sub viewport the same size as the main viewport
when the window is resized.

Everything else is manual. Place a camera and the view model inside the ``SubViewport`` child,
and keep that camera's field of view in sync with the world camera yourself.
