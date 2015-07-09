React = require 'react-native'
MainView = require './views/main'

App = React.createClass
    render: ->
        <MainView myCustomProp={'!'}>
        </MainView>

module.exports = App