# -*- coding: utf-8 -*-

from wtforms import (Form, TextField, DecimalField, TextAreaField,
                     SelectField, validators)

from pyramid.i18n import TranslationString as _

from ..generic.forms import required_marker, BooleanField


class ItemForm(Form):
    name = TextField(required_marker(u'Name'), [validators.Required()])
    type = SelectField(required_marker(u'Type'),
        choices=[(u'TRADE', u'Trade'), (u'SALE', u'Sale')])
    price = DecimalField(required_marker(u'Price'))
    trade_with = TextField(required_marker(u'Trade with'))
    description = TextAreaField(required_marker(u'Description'),
        [validators.Required()])
    reason = TextField(_(u'Reason'))
    quantity = TextField(required_marker(u'Quantity'), default=1)
    is_draft = BooleanField(_(u'Draft'))
    tags = TextField(_(u"Tags"))

    def validate_price(form, field):
        """
        Require the price field if this item is for SALE.
        """
        # if the item type is not SALE, just ignore the price field errors
        if form.type.data != 'SALE':
            field.errors = []
        elif form.type.data == 'SALE' and not field.data:
            raise validators.ValidationError(_(u"This field is required"))

    def validate_trade_with(form, field):
        """
        Require the trade_with field if this item is for TRADE.
        """
        # if the item type is not TRADE, just ignore the trade_with field errors
        if form.type.data != 'TRADE':
            field.errors = []
        elif form.type.data == 'TRADE' and not field.data:
            raise validators.ValidationError(_(u"This field is required"))
