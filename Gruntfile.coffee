'use strict'

module.exports = (grunt)->
  # project configuration
  grunt.initConfig
    # load package information
    pkg: grunt.file.readJSON 'package.json'

    meta:
      banner: "/* ===========================================================\n" +
        "# <%= pkg.name %> - v<%= pkg.version %>\n" +
        "# ==============================================================\n" +
        "# Copyright (C) 2013 <%= pkg.author.name %>\n" +
        "#\n" +
        "# This program is free software; you can redistribute it and/or modify\n" +
        "# it under the terms of the GNU General Public License as published by\n" +
        "# the Free Software Foundation; either version 2 of the License, or\n" +
        "# (at your option) any later version.\n" +
        "#\n" +
        "# This program is distributed in the hope that it will be useful,\n" +
        "# but WITHOUT ANY WARRANTY; without even the implied warranty of\n" +
        "# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n" +
        "# GNU General Public License for more details.\n" +
        "#\n" +
        "# You should have received a copy of the GNU General Public License along\n" +
        "# with this program; if not, write to the Free Software Foundation, Inc.,\n" +
        "# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.\n" +
        "*/\n"

    coffeelint:
      options:
        indentation:
          value: 2
          level: "error"
        no_trailing_semicolons:
          level: "error"
        no_trailing_whitespace:
          level: "error"
        max_line_length:
          level: "ignore"
      default: ["Gruntfile.coffee", "src/**/*.coffee"]

    clean:
      default: "lib"
      test: "spec"

    coffee:
      options:
        bare: true
      default:
        expand: true
        flatten: true
        cwd: "src/coffee"
        src: ["*.coffee"]
        dest: "lib"
        ext: ".js"
      test:
        expand: true
        flatten: true
        cwd: "src/spec"
        src: ["*.spec.coffee"]
        dest: "spec"
        ext: ".spec.js"

    concat:
      options:
        banner: "<%= meta.banner %>"
      default:
        expand: true
        flatten: true
        cwd: "lib"
        src: ["*.js"]
        dest: "lib"
        ext: ".js"

    # watching for changes
    watch:
      default:
        files: ["src/coffee/*.coffee"]
        tasks: ["build"]
      test:
        files: ["src/**/*.coffee"]
        tasks: ["test"]

    shell:
      options:
        stdout: true
        stderr: true
        failOnError: true
      coverage:
        command: "istanbul cover jasmine-node --captureExceptions spec && cat ./coverage/lcov.info | ./node_modules/coveralls/bin/coveralls.js && rm -rf ./coverage"
      jasmine:
        command: "jasmine-node --captureExceptions spec"

  # load plugins that provide the tasks defined in the config
  grunt.loadNpmTasks "grunt-coffeelint"
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-shell"
  grunt.loadNpmTasks "grunt-bump"

  # register tasks
  grunt.registerTask "build", ["clean", "coffeelint", "coffee", "concat"]
  grunt.registerTask "test", ["build", "shell:jasmine"]
  grunt.registerTask "coverage", ["build", "shell:coverage"]
