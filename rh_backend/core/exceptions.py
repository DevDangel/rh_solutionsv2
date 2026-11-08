import logging

from rest_framework import status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import exception_handler

logger = logging.getLogger(__name__)


def custom_exception_handler(exc, context):
    """
    Manejador global de excepciones para Django REST Framework.
    Cumple .agents/rules/security_rules.md:
    - Estandariza las respuestas de error en { status, message, errors }.
    - Jamás expone str(e) ni trazas de servidor en errores 500.
    """
    response = exception_handler(exc, context)

    if response is not None:
        if isinstance(exc, ValidationError):
            mensaje = "Los datos enviados contienen errores de validación."
            if isinstance(response.data, dict) and "detail" in response.data:
                detalle_val = response.data["detail"]
                mensaje = (
                    str(detalle_val[0])
                    if isinstance(detalle_val, list) and detalle_val
                    else str(detalle_val)
                )
            elif isinstance(response.data, dict):
                primer_campo = next(iter(response.data.values()), None)
                if isinstance(primer_campo, list) and primer_campo:
                    mensaje = str(primer_campo[0])

            return Response(
                {
                    "status": "error",
                    "message": mensaje,
                    "errors": response.data if isinstance(response.data, dict) else {},
                },
                status=response.status_code,
            )

        detalle = (
            response.data.get("detail")
            if isinstance(response.data, dict)
            else "No se pudo completar la operación."
        )
        return Response(
            {
                "status": "error",
                "message": str(detalle),
            },
            status=response.status_code,
        )

    logger.exception("Excepción no controlada en %s", context.get("view"))
    return Response(
        {
            "status": "error",
            "message": "Ocurrió un error interno en el servidor. Inténtalo de nuevo más tarde.",
        },
        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )
