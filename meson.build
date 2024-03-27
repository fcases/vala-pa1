project('vala app', 'vala', 'c')

vapi_dir = meson.current_source_dir() / 'vapi'

add_project_arguments(['--vapidir', vapi_dir], language: 'vala')

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk+-3.0'),
    dependency('portaudio-2.0'),
]

sources = files('src/main.vala','src/gtk.vala','src/pa.vala','src/fft.vala')

executable('pa1_v', sources, dependencies: dependencies)

