# -*- coding: utf-8 -*-

import wtforms

from pyramid.i18n import TranslationString as _


def required_marker(label_text):
    return '%s <span class="required-marker">*</span>' % _(label_text)


class BooleanField(wtforms.BooleanField):
    def process_formdata(self, valuelist):
        # Its not safe to assume that an unchecked field won't be submitted,
        # when using via ajax (ie. Backbone model's .save) sometimes its
        # better to include the falsy field. So be safe, we filter valuelist
        # instead and check if we can find a truthy value and cast to bool
        # from there.
        self.data = bool(filter(lambda e: e, valuelist))
