/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var t = require('i18n!necropolis');

  return {
    lich: t('lich', 'Lich'),

    archLich: t('lich', {
      context: 'arch',
      defaultValue: 'Arch Lich'
    }),

    vampire: t('vampire', {
      defaultValue: 'Vampire'
    })
  };
});