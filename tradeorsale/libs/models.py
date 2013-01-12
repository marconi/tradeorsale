# -*- coding: utf-8 -*-

from datetime import datetime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import Query, scoped_session, sessionmaker
from sqlalchemy.orm import class_mapper, ColumnProperty
from sqlalchemy import Column, Boolean, DateTime


class ModelMixin(object):

    def to_dict(self, exclude=True):
        """
        Returns a dict version of the current object in context.
        Excludes is_deleted and updated fields if present.
        """
        to_exlude = ['is_deleted', 'updated']
        cols = [prop.key for prop in class_mapper(self.__class__).iterate_properties
                if isinstance(prop, ColumnProperty)]
        data = {}
        for col in cols:
            if (col not in to_exlude and exclude) or not exclude:
                data[col] = getattr(self, col)
        return data

    @classmethod
    def alembicfy_cols(cls, model_class):
        """
        Returns unpackable list of fields for use with alembic migration.
        """
        cols = [model_class.__tablename__]
        for colname in dir(model_class):
            col = getattr(model_class, colname)
            if isinstance(col, Column):
                col.name = colname
                cols.append(col)
        return cols


class AuditableModel(object):
    is_deleted = Column(Boolean, default=False)
    created = Column(DateTime, default=datetime.now)
    updated = Column(DateTime, nullable=True, default=None)


class AuditableQuery(Query):
    def __new__(cls, *args, **kwargs):
        if args and hasattr(args[0][0], "is_deleted"):
            return Query(*args, **kwargs).filter_by(is_deleted=False)
        else:
            return object.__new__(cls)


DBSession = scoped_session(sessionmaker(query_cls=AuditableQuery))
Base = declarative_base()


def initialize_db(engine):
    DBSession.configure(bind=engine)
    Base.metadata.bind = engine
    Base.metadata.create_all(engine)
