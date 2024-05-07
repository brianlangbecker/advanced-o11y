<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\HttpFoundation\Response;
use OpenTelemetry\API\Common\Instrumentation\CachedInstrumentation;
use OpenTelemetry\API\Trace\Span;
use OpenTelemetry\API\Trace\StatusCode;
use OpenTelemetry\Context\Context;
use OpenTelemetry\Contrib\Otlp\ContentTypes;
use OpenTelemetry\Contrib\Otlp\OtlpHttpTransportFactory;
use OpenTelemetry\Contrib\Otlp\SpanExporter;
use OpenTelemetry\SDK\Trace\SpanProcessor\SimpleSpanProcessor;
use OpenTelemetry\SDK\Trace\TracerProvider;

require dirname(__DIR__) . '/../vendor/autoload.php';



class YearController extends AbstractController
{
    #[Route('/year', name: 'app_year')]
    public function getRandomYear(): Response
    {
        $currentYear = date("Y"); // Get the current year
        usleep(rand(0, 5000)); // Simulate a small delay
        $randomYear = rand(2015, $currentYear); // Get a random year between 2015 and current year

        return new Response((string) $randomYear, 200, ['Content-Type' => 'text/plain']);
    }

}

\OpenTelemetry\Instrumentation\hook(
    class: YearController::class,
    function: 'run',
    pre: static function (YearController $demo, array $params, string $class, string $function, ?string $filename, ?int $lineno) {
    $transport = (new OtlpHttpTransportFactory())->create('https://api.honeycomb.io/v1/traces', ContentTypes::JSON, "x-honeycomb-team=eyKPDnLwa0poTC3XvvTfGD");
    $exporter = new SpanExporter($transport);

    echo 'Starting OTLP+json example';

    $tracerProvider =  new TracerProvider(
    new SimpleSpanProcessor(
        $exporter
    ) );

    $tracer = $tracerProvider->getTracer('yearsssss');

        static $instrumentation;
        $instrumentation ??= new CachedInstrumentation('year');
        $span = $tracer->spanBuilder('YearController-getRandomYear')->startSpan();
        Context::storage()->attach($span->storeInContext(Context::getCurrent()));
    },
    post: static function (YearController $demo, array $params, $returnValue, ?Throwable $exception) {
        
        $scope = Context::storage()->scope();
        $scope->detach();
        $span = Span::fromContext($scope->context());
        if ($exception) {
            $span->recordException($exception);
            $span->setStatus(StatusCode::STATUS_ERROR);
        }
        $span->end();
    }
);